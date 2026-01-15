class GraphRagAnalysisJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3, dead: true

  # GraphRAG 분석 백그라운드 잡
  # - 비동기로 오답 분석 수행
  # - 대량 데이터 처리 지원
  # - 에러 처리 및 재시도

  def perform(user_id, question_id, selected_answer, study_set_id)
    user = User.find(user_id)
    question = Question.find(question_id)
    study_set = StudySet.find(study_set_id)

    Rails.logger.info("Starting GraphRAG analysis job for user #{user_id}, question #{question_id}")

    begin
      # GraphRAG 서비스 실행
      graph_rag_service = GraphRagService.new
      analysis_result = graph_rag_service.analyze_wrong_answer(user, question, selected_answer, study_set)

      # 오답 분석 서비스 실행
      error_analysis_service = ErrorAnalysisService.new
      error_analysis = error_analysis_service.analyze_error_in_depth(user, question, selected_answer, analysis_result)

      # 학습 경로 생성
      learning_path = error_analysis_service.generate_learning_path(user, analysis_result, study_set)

      # 추천 생성
      recommendation_service = RecommendationService.new
      recommendation = recommendation_service.generate_comprehensive_recommendation(user, study_set, analysis_result)

      # 완료 로그
      Rails.logger.info("GraphRAG analysis completed for analysis_result #{analysis_result.id}")
      Rails.logger.info("Learning recommendation created: #{recommendation.id}")

      # 웹소켓 알림 (선택사항)
      notify_analysis_complete(user, analysis_result, recommendation)

      analysis_result
    rescue StandardError => e
      Rails.logger.error("Error in GraphRAG analysis job: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      # 분석 결과가 이미 있으면 실패 표시
      analysis_result = AnalysisResult.find_by(
        user_id: user_id,
        question_id: question_id,
        study_set_id: study_set_id
      )
      analysis_result&.mark_failed!(e.message, e.backtrace.first(10).join("\n"))

      raise e
    end
  end

  # 배치 분석 (여러 문제 한 번에 분석)
  def self.analyze_batch(user, questions, study_set)
    questions.each do |question|
      selected_answer = determine_selected_answer(user, question)
      next unless selected_answer.present?

      perform_later(user.id, question.id, selected_answer, study_set.id)
    end
  end

  # 사용자의 모든 오답 일괄 분석
  def self.analyze_all_wrong_answers(user, study_set)
    wrong_answers = user.wrong_answers.where(study_set_id: study_set.id)

    wrong_answers.each do |wa|
      perform_later(user.id, wa.question_id, wa.selected_answer, study_set.id)
    end
  end

  # 재분석: 기존 분석 업데이트
  def self.reanalyze(analysis_result_id)
    analysis = AnalysisResult.find(analysis_result_id)

    perform_later(
      analysis.user_id,
      analysis.question_id,
      analysis.llm_analysis_metadata&.fetch('selected_answer', analysis.question.answer),
      analysis.study_set_id
    )
  end

  private

  def notify_analysis_complete(user, analysis_result, recommendation)
    # ActionCable을 통한 실시간 알림 (선택사항)
    # AnalysisChannel.broadcast_to(
    #   user,
    #   {
    #     type: 'analysis_complete',
    #     analysis_id: analysis_result.id,
    #     recommendation_id: recommendation.id,
    #     concept_gap_score: analysis_result.concept_gap_score,
    #     message: "분석이 완료되었습니다."
    #   }
    # )
  end

  def determine_selected_answer(user, question)
    # 사용자가 이 문제에 대해 선택한 답 찾기
    wrong_answer = user.wrong_answers.find_by(question_id: question.id)
    wrong_answer&.selected_answer
  end
end
