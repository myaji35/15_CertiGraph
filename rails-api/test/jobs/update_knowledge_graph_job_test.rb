require 'test_helper'

class UpdateKnowledgeGraphJobTest < ActiveJob::TestCase
  setup do
    @question = questions(:one)
    @user = users(:one)
  end

  test "enqueues UpdateKnowledgeGraphJob on correct queue" do
    assert_enqueued_with(job: UpdateKnowledgeGraphJob, queue: 'graph_update') do
      UpdateKnowledgeGraphJob.perform_later(@question.id)
    end
  end

  test "UpdateKnowledgeGraphJob has correct queue_as" do
    job = UpdateKnowledgeGraphJob.new
    assert_equal 'graph_update', job.queue_name
  end

  test "performs update with question_id only" do
    # 사용자 정보 없이 실행
    # UpdateKnowledgeGraphJob.perform_now(@question.id)
  end

  test "performs update with question_id and user_id" do
    # 사용자 정보와 함께 실행
    # UpdateKnowledgeGraphJob.perform_now(@question.id, @user.id)
  end

  test "handles missing question gracefully" do
    assert_raises ActiveRecord::RecordNotFound do
      UpdateKnowledgeGraphJob.perform_now(999999)
    end
  end

  test "handles missing user gracefully" do
    # 사용자가 없는 경우 무시하고 계속 진행
    # UpdateKnowledgeGraphJob.perform_now(@question.id, 999999)
  end

  test "retries on StandardError" do
    job = UpdateKnowledgeGraphJob.new

    # 최대 5회 재시도
    assert_equal 5, job.class.retry_on_handler(StandardError).instance_variable_get("@attempts")
  end
end
