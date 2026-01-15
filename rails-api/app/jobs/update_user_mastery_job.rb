class UpdateUserMasteryJob
  include Sidekiq::Job

  sidekiq_options retry: 3

  def perform(user_id, question_id, correct:, time_minutes: 0)
    user = User.find(user_id)
    question = Question.find(question_id)
    study_material = question.study_material

    # 해당 질문과 관련된 모든 개념 찾기
    knowledge_nodes = KnowledgeNode.where(study_material_id: study_material.id)

    # 각 개념에 대해 사용자 숙달도 업데이트
    knowledge_nodes.each do |node|
      mastery = UserMastery.find_or_create_by(user_id: user.id, knowledge_node_id: node.id)
      mastery.update_with_attempt(correct: correct, time_minutes: time_minutes)
    end

    Rails.logger.info("User mastery updated for user #{user_id}, question #{question_id}")
  rescue => e
    Rails.logger.error("UpdateUserMasteryJob failed: #{e.message}")
    raise e
  end
end
