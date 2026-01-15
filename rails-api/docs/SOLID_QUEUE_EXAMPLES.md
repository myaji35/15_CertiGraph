# Solid Queue 사용 예제

## 1. 컨트롤러에서 Job 큐에 추가

### StudyMaterials 컨트롤러 예제

```ruby
class StudyMaterialsController < ApplicationController
  def create
    @study_material = current_user.study_materials.build(study_material_params)

    if @study_material.save
      # PDF 처리 작업을 백그라운드에서 실행
      ProcessPdfJob.perform_later(@study_material.id)

      render json: @study_material, status: :created
    else
      render json: @study_material.errors, status: :unprocessable_entity
    end
  end

  def upload_pdf
    @study_material = StudyMaterial.find(params[:id])

    if @study_material.pdf_file.attach(params[:file])
      # PDF 업로드 후 처리
      ProcessPdfJob.perform_later(@study_material.id)

      render json: { message: "PDF uploaded and processing started", study_material: @study_material }
    else
      render json: { error: "Failed to upload PDF" }, status: :unprocessable_entity
    end
  end

  def status
    @study_material = StudyMaterial.find(params[:id])

    render json: {
      id: @study_material.id,
      status: @study_material.status,
      error_message: @study_material.error_message,
      extracted_data: @study_material.extracted_data,
      created_at: @study_material.created_at,
      updated_at: @study_material.updated_at
    }
  end

  private

  def study_material_params
    params.require(:study_material).permit(:title, :description, :pdf_file)
  end
end
```

## 2. 모델에서 Job 큐에 추가

### StudyMaterial 모델
```ruby
class StudyMaterial < ApplicationRecord
  has_one_attached :pdf_file
  has_many :questions, dependent: :destroy

  after_create :enqueue_processing

  enum status: { pending: 'pending', processing: 'processing', completed: 'completed', failed: 'failed' }

  # Callback: 생성 후 자동으로 처리 큐에 추가
  private

  def enqueue_processing
    ProcessPdfJob.set(wait: 5.seconds).perform_later(id)
  end
end
```

### Question 모델
```ruby
class Question < ApplicationRecord
  belongs_to :study_material
  has_one_attached :image
  has_many :options, dependent: :destroy
  has_many :test_questions, dependent: :destroy

  # 임베딩 생성을 위한 콜백
  after_create :enqueue_embedding_generation

  private

  def enqueue_embedding_generation
    return if embedding.present?

    GenerateEmbeddingJob.set(wait: 10.seconds).perform_later(id)
  end
end
```

## 3. 직접 Job 실행

### 동기 실행 (즉시)
```ruby
# 개발/테스트 환경에서 사용
ProcessPdfJob.perform_now(study_material_id)
GenerateEmbeddingJob.perform_now(question_id)
UpdateKnowledgeGraphJob.perform_now(question_id)
```

### 비동기 실행 (큐에 추가)
```ruby
# 일반적인 비동기 실행
ProcessPdfJob.perform_later(study_material_id)

# 즉시 큐에 추가하되, 처리는 나중에
GenerateEmbeddingJob.perform_later(question_id)
```

### 예약된 실행
```ruby
# 1시간 후에 실행
ProcessPdfJob.set(wait: 1.hour).perform_later(study_material_id)

# 특정 시간에 실행
ProcessPdfJob.set(wait_until: Date.tomorrow.noon).perform_later(study_material_id)

# 5분 후 실행
GenerateEmbeddingJob.set(wait: 5.minutes).perform_later(question_id)
```

## 4. 일괄 처리

```ruby
class BulkProcessPdfJob < ApplicationJob
  queue_as :default

  def perform(study_material_ids)
    study_material_ids.each do |id|
      # 각 자료마다 처리 작업 큐에 추가
      ProcessPdfJob.perform_later(id)
    end

    Rails.logger.info("Enqueued #{study_material_ids.count} PDF processing jobs")
  end
end

# 사용
study_material_ids = [1, 2, 3, 4, 5]
BulkProcessPdfJob.perform_later(study_material_ids)
```

## 5. 예외 처리와 재시도

### 커스텀 Job 클래스
```ruby
class CustomProcessJob < ApplicationJob
  queue_as :default

  # 특정 예외에만 재시도
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
  retry_on Timeout::Error, wait: 10.seconds, attempts: 3
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  # 특정 예외는 무시 (폐기)
  discard_on ActiveJob::DeserializationError

  def perform(record_id)
    record = MyModel.find(record_id)
    # 처리...
  rescue RecordNotFoundError => e
    Rails.logger.warn("Record not found: #{e.message}")
    # 무시하고 계속
  end
end
```

## 6. Job 모니터링

### Rails 콘솔에서
```ruby
# 대기 중인 작업 수
SolidQueue::Job.where(finished_at: nil).count

# 특정 큐의 작업 수
SolidQueue::Job.where(queue_name: 'pdf_processing', finished_at: nil).count

# 실패한 작업
SolidQueue::FailedExecution.all

# 특정 Job 클래스의 작업
SolidQueue::Job.where(class_name: 'ProcessPdfJob').count

# 가장 오래된 대기 작업
SolidQueue::Job.where(finished_at: nil).order(:created_at).first

# 실행 중인 작업
SolidQueue::ClaimedExecution.joins(:ready_execution).pluck(:class_name).uniq
```

### Job 통계
```ruby
# 시간별 작업 완료 수
SolidQueue::Job.where("finished_at >= ?", 1.hour.ago).group_by { |j| j.finished_at.hour }.map { |h, jobs| [h, jobs.count] }

# 큐별 작업 상태
SolidQueue::Job.group(:queue_name).select(:queue_name).count

# 가장 많은 재시도가 필요한 작업
SolidQueue::Job.where(finished_at: nil).order(executions: :desc).limit(10)
```

## 7. 웹 인터페이스 대시보드 (선택)

```ruby
# Gemfile에 추가
gem 'solid_queue', path: Rails.root.join('gems/solid_queue')

# config/routes.rb
mount SolidQueue::Engine => '/solid_queue'

# 따로 대시보드 설정
class SolidQueueDashboardController < ApplicationController
  def index
    @job_count = SolidQueue::Job.count
    @pending_jobs = SolidQueue::Job.where(finished_at: nil).count
    @failed_jobs = SolidQueue::FailedExecution.count
    @scheduled_jobs = SolidQueue::ScheduledExecution.count
  end
end
```

## 8. 테스트에서 Job 처리

```ruby
require 'test_helper'

class StudyMaterialsControllerTest < ActionDispatch::IntegrationTest
  test "creating study material enqueues ProcessPdfJob" do
    # 동기 처리 모드로 테스트 (Rails 기본)
    assert_enqueued_with(job: ProcessPdfJob) do
      post '/study_materials', params: {
        study_material: { title: 'Test Material', pdf_file: fixture_file_upload('test.pdf') }
      }
    end
  end

  test "PDF processing job works correctly" do
    study_material = study_materials(:one)
    study_material.pdf_file.attach(fixture_file_upload('test.pdf'))

    # 동기 실행으로 테스트
    ProcessPdfJob.perform_now(study_material.id)

    # 결과 확인
    assert_equal 'completed', study_material.reload.status
    assert study_material.questions.any?
  end

  test "embedding generation retries on timeout" do
    question = questions(:one)

    # 재시도 정책 확인
    job = GenerateEmbeddingJob.new
    assert_equal 5, job.class.retry_on_handler(StandardError)&.attempts || 3
  end
end
```

## 9. 오류 처리와 알림

```ruby
class ProcessPdfJob < ApplicationJob
  queue_as :pdf_processing

  def perform(study_material_id)
    study_material = StudyMaterial.find(study_material_id)

    begin
      # 처리...
      study_material.update(status: 'completed')
    rescue => e
      Rails.logger.error("PDF processing failed: #{e.message}")

      # 오류 알림
      send_error_notification(study_material, e)

      # 상태 업데이트
      study_material.update(
        status: 'failed',
        error_message: e.message
      )

      # 재시도 전에 관리자에게 알림
      if executions >= 3
        notify_admin("PDF processing failed after #{executions} attempts", study_material)
      end

      raise e  # 재시도를 위해 에러 발생
    end
  end

  private

  def send_error_notification(study_material, error)
    # 이메일, Slack, 또는 다른 채널로 알림
    ErrorNotificationMailer.pdf_processing_failed(
      study_material.user_id,
      study_material.id,
      error.message
    ).deliver_later
  end

  def notify_admin(message, study_material)
    AdminNotificationService.notify(message, { study_material_id: study_material.id })
  end
end
```

## 10. 성능 최적화 예제

### 배치 처리
```ruby
class BatchEmbeddingJob < ApplicationJob
  queue_as :embedding_generation

  def perform(question_ids)
    questions = Question.where(id: question_ids)

    # 배치로 임베딩 생성
    embeddings = generate_batch_embeddings(questions)

    questions.each_with_index do |question, index|
      question.update(embedding: embeddings[index])
    end
  end

  private

  def generate_batch_embeddings(questions)
    # OpenAI 배치 API 호출
    embedding_service = EmbeddingService.new
    embedding_service.batch_generate(
      questions.map { |q| "#{q.content} #{q.passage}" }
    )
  end
end

# 사용
question_ids = Question.where(embedding: nil).pluck(:id).first(100)
BatchEmbeddingJob.perform_later(question_ids)
```

### 우선순위 기반 처리
```ruby
# 높은 우선순위 작업
ProcessPdfJob.set(queue: :high_priority).perform_later(id)

# 낮은 우선순위 작업
ProcessPdfJob.set(queue: :low_priority).perform_later(id)
```

이러한 예제들을 참고하여 프로젝트에 맞는 백그라운드 작업 처리를 구현할 수 있습니다.
