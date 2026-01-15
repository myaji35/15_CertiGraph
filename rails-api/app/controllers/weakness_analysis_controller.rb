# Weakness Analysis Controller
# 오답 분석 및 약점 진단 API

class WeaknessAnalysisController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_material, except: [:user_overall_analysis]

  # POST /api/weakness_analysis/:study_material_id/analyze
  # 특정 학습자료에 대한 사용자 약점 분석
  def analyze
    begin
      # GraphRAG 서비스로 약점 분석
      graph_rag_service = GraphRagService.new(@study_material, current_user)
      analysis_result = graph_rag_service.analyze_user_weaknesses

      # 분석 결과 저장
      saved_result = AnalysisResult.create!(
        user: current_user,
        study_material: @study_material,
        analysis_type: 'weakness_analysis',
        weak_concepts: analysis_result[:weak_concepts],
        prerequisites: analysis_result[:prerequisites],
        related_concepts: analysis_result[:related_concepts],
        reasoning: analysis_result[:reasoning],
        recommendations: analysis_result[:recommendations],
        confidence_score: analysis_result[:confidence_score]
      )

      render json: {
        success: true,
        analysis_result: {
          id: saved_result.id,
          weak_concepts: saved_result.weak_concepts,
          prerequisites: saved_result.prerequisites,
          recommendations: saved_result.recommendations,
          confidence_score: saved_result.confidence_score,
          analyzed_at: saved_result.created_at
        }
      }
    rescue StandardError => e
      Rails.logger.error("[WeaknessAnalysis] Failed: #{e.message}")
      render json: {
        success: false,
        message: "Analysis failed: #{e.message}"
      }, status: :internal_server_error
    end
  end

  # POST /api/weakness_analysis/:study_material_id/analyze_error
  # 특정 오답에 대한 상세 분석
  def analyze_error
    question = Question.find(params[:question_id])
    selected_answer = params[:selected_answer]

    if question.study_material_id != @study_material.id
      return render json: {
        success: false,
        message: 'Question does not belong to this study material'
      }, status: :forbidden
    end

    begin
      # GraphRAG 분석 결과 가져오기
      graph_rag_service = GraphRagService.new(@study_material, current_user)
      analysis = graph_rag_service.analyze_wrong_answer(question, selected_answer)

      # 오답 상세 분석
      error_analysis_service = ErrorAnalysisService.new
      detailed_analysis = error_analysis_service.analyze_error_in_depth(
        current_user,
        question,
        selected_answer,
        analysis
      )

      render json: {
        success: true,
        error_analysis: {
          question_id: question.id,
          selected_answer: selected_answer,
          correct_answer: question.answer,
          classification: detailed_analysis[:error_classification],
          conceptual_gaps: detailed_analysis[:conceptual_gaps],
          error_patterns: detailed_analysis[:error_patterns],
          similar_mistakes: detailed_analysis[:similar_mistakes],
          knowledge_connections: detailed_analysis[:knowledge_connections]
        }
      }
    rescue ActiveRecord::RecordNotFound
      render json: {
        success: false,
        message: 'Question not found'
      }, status: :not_found
    rescue StandardError => e
      render json: {
        success: false,
        message: "Error analysis failed: #{e.message}"
      }, status: :internal_server_error
    end
  end

  # GET /api/weakness_analysis/:study_material_id/weak_concepts
  # 약한 개념 목록 조회
  def weak_concepts
    graph_rag_service = GraphRagService.new(@study_material, current_user)
    weak_concepts = graph_rag_service.identify_weak_concepts

    render json: {
      success: true,
      weak_concepts: weak_concepts.map do |concept|
        {
          concept_id: concept[:concept_id],
          concept_name: concept[:name],
          mastery_level: concept[:mastery_level],
          attempts: concept[:attempts],
          correct_attempts: concept[:correct_attempts],
          accuracy: concept[:accuracy],
          importance: concept[:importance],
          difficulty: concept[:difficulty]
        }
      end
    }
  rescue StandardError => e
    render json: {
      success: false,
      message: "Failed to retrieve weak concepts: #{e.message}"
    }, status: :internal_server_error
  end

  # POST /api/weakness_analysis/:study_material_id/learning_path
  # 약점 개선을 위한 학습 경로 생성
  def generate_learning_path
    begin
      # 최근 분석 결과 가져오기
      analysis_result = AnalysisResult.where(
        user: current_user,
        study_material: @study_material,
        analysis_type: 'weakness_analysis'
      ).order(created_at: :desc).first

      unless analysis_result
        return render json: {
          success: false,
          message: 'No analysis result found. Please run analysis first.'
        }, status: :unprocessable_entity
      end

      # 학습 경로 생성
      error_analysis_service = ErrorAnalysisService.new
      learning_path = error_analysis_service.generate_learning_path(
        current_user,
        analysis_result,
        @study_material.study_set
      )

      render json: {
        success: true,
        learning_path: learning_path
      }
    rescue StandardError => e
      render json: {
        success: false,
        message: "Failed to generate learning path: #{e.message}"
      }, status: :internal_server_error
    end
  end

  # GET /api/weakness_analysis/:study_material_id/error_patterns
  # 사용자의 오답 패턴 분석
  def error_patterns
    error_analysis_service = ErrorAnalysisService.new
    patterns = error_analysis_service.detect_error_patterns(current_user, nil)

    render json: {
      success: true,
      error_patterns: patterns
    }
  rescue StandardError => e
    render json: {
      success: false,
      message: "Failed to detect error patterns: #{e.message}"
    }, status: :internal_server_error
  end

  # GET /api/weakness_analysis/:study_material_id/recommendations
  # 맞춤형 학습 추천
  def recommendations
    begin
      graph_rag_service = GraphRagService.new(@study_material, current_user)
      recommendations = graph_rag_service.generate_recommendations

      render json: {
        success: true,
        recommendations: recommendations
      }
    rescue StandardError => e
      render json: {
        success: false,
        message: "Failed to generate recommendations: #{e.message}"
      }, status: :internal_server_error
    end
  end

  # GET /api/weakness_analysis/user_overall_analysis
  # 전체 학습자료에 대한 사용자 종합 분석
  def user_overall_analysis
    study_materials = current_user.study_materials

    overall_stats = {
      total_questions_attempted: 0,
      total_correct: 0,
      total_wrong: 0,
      accuracy_rate: 0.0,
      weak_topics: [],
      strong_topics: [],
      improvement_trend: []
    }

    study_materials.each do |material|
      exam_answers = current_user.exam_answers.joins(:question)
                                  .where(questions: { study_material_id: material.id })

      overall_stats[:total_questions_attempted] += exam_answers.count
      overall_stats[:total_correct] += exam_answers.where(is_correct: true).count
      overall_stats[:total_wrong] += exam_answers.where(is_correct: false).count
    end

    if overall_stats[:total_questions_attempted] > 0
      overall_stats[:accuracy_rate] = (
        overall_stats[:total_correct].to_f / overall_stats[:total_questions_attempted]
      ).round(3)
    end

    # 약한 주제 찾기
    weak_topics = find_weak_topics(current_user)
    overall_stats[:weak_topics] = weak_topics

    # 강한 주제 찾기
    strong_topics = find_strong_topics(current_user)
    overall_stats[:strong_topics] = strong_topics

    # 개선 추이
    improvement_trend = calculate_improvement_trend(current_user)
    overall_stats[:improvement_trend] = improvement_trend

    render json: {
      success: true,
      overall_analysis: overall_stats
    }
  end

  # GET /api/weakness_analysis/:study_material_id/history
  # 분석 이력 조회
  def history
    analysis_results = AnalysisResult.where(
      user: current_user,
      study_material: @study_material
    ).order(created_at: :desc)
     .limit(params[:limit] || 10)

    render json: {
      success: true,
      history: analysis_results.map do |result|
        {
          id: result.id,
          analysis_type: result.analysis_type,
          weak_concepts_count: result.weak_concepts&.length || 0,
          confidence_score: result.confidence_score,
          analyzed_at: result.created_at
        }
      end
    }
  end

  private

  def set_study_material
    @study_material = StudyMaterial.find(params[:study_material_id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: 'Study material not found'
    }, status: :not_found
  end

  def find_weak_topics(user)
    exam_answers = user.exam_answers.joins(:question)
    topics = exam_answers.group('questions.topic')
                        .select('questions.topic, COUNT(*) as total, SUM(CASE WHEN exam_answers.is_correct THEN 1 ELSE 0 END) as correct')
                        .having('COUNT(*) >= 5') # 최소 5문제 이상

    weak_topics = topics.map do |topic_stat|
      accuracy = topic_stat.correct.to_f / topic_stat.total
      {
        topic: topic_stat.topic,
        accuracy: accuracy.round(3),
        total_attempts: topic_stat.total
      }
    end.select { |t| t[:accuracy] < 0.6 }
     .sort_by { |t| t[:accuracy] }
     .take(5)

    weak_topics
  end

  def find_strong_topics(user)
    exam_answers = user.exam_answers.joins(:question)
    topics = exam_answers.group('questions.topic')
                        .select('questions.topic, COUNT(*) as total, SUM(CASE WHEN exam_answers.is_correct THEN 1 ELSE 0 END) as correct')
                        .having('COUNT(*) >= 5')

    strong_topics = topics.map do |topic_stat|
      accuracy = topic_stat.correct.to_f / topic_stat.total
      {
        topic: topic_stat.topic,
        accuracy: accuracy.round(3),
        total_attempts: topic_stat.total
      }
    end.select { |t| t[:accuracy] >= 0.8 }
     .sort_by { |t| -t[:accuracy] }
     .take(5)

    strong_topics
  end

  def calculate_improvement_trend(user)
    # 최근 30일간 주간 정확도 추이
    30.days.ago.to_date.step(Date.today, 7).map do |week_start|
      week_end = week_start + 6.days
      answers = user.exam_answers.where(created_at: week_start..week_end)

      if answers.count > 0
        {
          week: week_start.to_s,
          accuracy: (answers.where(is_correct: true).count.to_f / answers.count).round(3),
          total_attempts: answers.count
        }
      end
    end.compact
  end
end
