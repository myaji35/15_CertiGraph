class ApplicationJob < ActiveJob::Base
  # Default queue
  queue_as :default

  # 데이터베이스 데드락 시 재시도
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3

  # 전체 에러에 대한 기본 재시도 정책
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  # 기본 존재하지 않는 레코드 삭제 (직렬화 에러)
  discard_on ActiveJob::DeserializationError

  # 작업 로깅
  before_enqueue do |job|
    Rails.logger.info("Job enqueued: #{job.class.name} with arguments: #{job.arguments.inspect}")
  end

  before_perform do |job|
    Rails.logger.info("Job started: #{job.class.name} with arguments: #{job.arguments.inspect}")
  end

  after_perform do |job|
    Rails.logger.info("Job completed: #{job.class.name}")
  end

  rescue_from(StandardError) do |exception|
    Rails.logger.error("Job failed: #{self.class.name}")
    Rails.logger.error("Error: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))
  end
end
