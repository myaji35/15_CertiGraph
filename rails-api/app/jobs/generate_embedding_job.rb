class GenerateEmbeddingJob < ApplicationJob
  queue_as :embedding_generation

  # 특정 에러에 대한 재시도 정책
  retry_on Timeout::Error, wait: 10.seconds, attempts: 3
  retry_on OpenAI::Error, wait: :exponentially_longer, attempts: 5
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # 임베딩 생성 실패 시 폐기
  discard_on ActiveJob::SerializationError

  def perform(embeddin_target_id, target_type = "question")
    case target_type
    when "question"
      generate_embedding_for_question(embeddin_target_id)
    when "study_material"
      generate_embedding_for_study_material(embeddin_target_id)
    else
      Rails.logger.warn("Unknown embedding target type: #{target_type}")
    end
  end

  private

  def generate_embedding_for_question(question_id)
    question = Question.find(question_id)
    return if question.embedding.present?  # 이미 임베딩이 있으면 스킵

    begin
      Rails.logger.info("Generating embedding for question: #{question_id}")

      # 임베딩 서비스 사용
      embedding_service = EmbeddingService.new
      success = embedding_service.generate_embedding_for_question(question)

      if success
        Rails.logger.info("Embedding generated successfully for question: #{question_id}")
        # 임베딩 생성 후 그래프 업데이트 작업 큐에 추가
        UpdateKnowledgeGraphJob.perform_later(question_id)
      else
        Rails.logger.warn("Failed to generate embedding for question: #{question_id}")
        raise "Embedding generation failed"
      end
    rescue StandardError => e
      Rails.logger.error("Error generating embedding for question #{question_id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise e  # 재시도를 위해 에러 발생
    end
  end

  def generate_embedding_for_study_material(study_material_id)
    study_material = StudyMaterial.find(study_material_id)

    begin
      Rails.logger.info("Generating embeddings for study_material: #{study_material_id}")

      embedding_service = EmbeddingService.new
      embedding_count = embedding_service.generate_embeddings_for_document(study_material)

      Rails.logger.info("Generated #{embedding_count} embeddings for study_material: #{study_material_id}")

      # 학습자료의 모든 질문에 대해 임베딩 생성 작업 큐에 추가
      study_material.questions.find_each do |question|
        GenerateEmbeddingJob.perform_later(question.id, "question")
      end
    rescue StandardError => e
      Rails.logger.error("Error generating embeddings for study_material #{study_material_id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise e
    end
  end
end
