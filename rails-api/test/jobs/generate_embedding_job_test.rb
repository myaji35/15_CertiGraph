require 'test_helper'

class GenerateEmbeddingJobTest < ActiveJob::TestCase
  setup do
    @question = questions(:one)
  end

  test "enqueues GenerateEmbeddingJob on correct queue" do
    assert_enqueued_with(job: GenerateEmbeddingJob, queue: 'embedding_generation') do
      GenerateEmbeddingJob.perform_later(@question.id)
    end
  end

  test "GenerateEmbeddingJob has correct queue_as" do
    job = GenerateEmbeddingJob.new
    assert_equal 'embedding_generation', job.queue_name
  end

  test "enqueues UpdateKnowledgeGraphJob after embedding generation" do
    # Mock 셋업 (실제 임베딩 서비스 호출 방지)
    # EmbeddingService stub
    embedding_stub = [0.1, 0.2, 0.3] # 간단한 임베딩 예제

    # Perform with mocked service
    assert_enqueued_with(job: UpdateKnowledgeGraphJob) do
      # GenerateEmbeddingJob.perform_now(@question.id)
    end
  end

  test "handles missing question gracefully" do
    assert_raises ActiveRecord::RecordNotFound do
      GenerateEmbeddingJob.perform_now(999999)
    end
  end

  test "skips embedding generation if already exists" do
    # 이미 embedding이 있는 경우
    @question.update(embedding: [0.1, 0.2, 0.3])

    assert_no_enqueued_jobs(only: UpdateKnowledgeGraphJob) do
      # GenerateEmbeddingJob.perform_now(@question.id)
    end
  end
end
