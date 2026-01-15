module Api
  module V1
    class GraphRagController < ApplicationController
      before_action :authenticate_user!
      before_action :set_study_set, only: [:analyze, :weaknesses, :recommendations, :learning_path]
      before_action :authorize_study_set_access!, only: [:analyze, :weaknesses, :recommendations, :learning_path]

      # POST /api/v1/graph_rag/analyze
      # 오답 분석 요청
      def analyze
        question = Question.find(analysis_params[:question_id])
        selected_answer = analysis_params[:selected_answer]

        # GraphRAG 분석 시작 (비동기)
        analysis_job = GraphRagAnalysisJob.perform_later(
          current_user.id,
          question.id,
          selected_answer,
          @study_set.id
        )

        render json: {
          status: 'analysis_started',
          job_id: analysis_job.job_id,
          message: '분석이 시작되었습니다. 잠시 후 결과를 확인하세요.'
        }, status: :accepted
      end

      # GET /api/v1/graph_rag/analysis/:analysis_id
      # 분석 결과 조회
      def analysis_result
        analysis = AnalysisResult.find(params[:analysis_id])
        authorize_analysis_access!(analysis)

        case analysis.status
        when 'completed'
          render json: analysis.to_detailed_json, status: :ok
        when 'processing'
          render json: {
            status: 'processing',
            message: '분석 중입니다. 잠시만 기다려주세요.'
          }, status: :ok
        when 'failed'
          render json: {
            status: 'failed',
            error: analysis.error_message
          }, status: :unprocessable_entity
        else
          render json: {
            status: 'pending',
            message: '분석 대기 중입니다.'
          }, status: :ok
        end
      end

      # GET /api/v1/study_sets/:study_set_id/graph_rag/weaknesses
      # 약점 조회
      def weaknesses
        # 분석 완료된 결과만 조회
        analyses = AnalysisResult.where(
          user_id: current_user.id,
          study_set_id: @study_set.id,
          status: 'completed'
        ).includes(:question).recent

        if analyses.empty?
          return render json: {
            weaknesses: [],
            message: '분석 결과가 없습니다.'
          }, status: :ok
        end

        # 약점 개념 집계
        weakness_concepts = aggregate_weaknesses(analyses)

        render json: {
          total_analyses: analyses.count,
          weakness_count: weakness_concepts.count,
          weaknesses: weakness_concepts,
          critical_weaknesses: weakness_concepts.select { |w| w[:gap_score] > 0.7 },
          recommended_action: recommend_action(weakness_concepts)
        }, status: :ok
      end

      # GET /api/v1/study_sets/:study_set_id/graph_rag/recommendations
      # 학습 추천 조회
      def recommendations
        recommendations = LearningRecommendation.where(
          user_id: current_user.id,
          study_set_id: @study_set.id,
          status: 'active'
        ).recent.limit(5)

        render json: {
          total_recommendations: recommendations.count,
          recommendations: recommendations.map(&:to_recommendation_json),
          next_recommended: recommendations.first&.to_detailed_json
        }, status: :ok
      end

      # GET /api/v1/study_sets/:study_set_id/graph_rag/learning-path
      # 학습 경로 조회
      def learning_path
        latest_recommendation = LearningRecommendation.where(
          user_id: current_user.id,
          study_set_id: @study_set.id
        ).recent.first

        if latest_recommendation.blank?
          return render json: {
            learning_path: [],
            message: '학습 경로가 생성되지 않았습니다. 먼저 분석을 완료해주세요.'
          }, status: :ok
        end

        render json: {
          recommendation_id: latest_recommendation.id,
          learning_path: latest_recommendation.learning_path,
          steps_count: latest_recommendation.learning_path_steps,
          estimated_hours: latest_recommendation.estimated_learning_hours,
          success_probability: latest_recommendation.success_probability,
          efficiency_index: latest_recommendation.learning_efficiency_index,
          progress: latest_recommendation.progress_tracking
        }, status: :ok
      end

      # POST /api/v1/graph_rag/recommendations/:recommendation_id/activate
      # 추천 활성화
      def activate_recommendation
        recommendation = LearningRecommendation.find(params[:recommendation_id])
        authorize_recommendation_access!(recommendation)

        recommendation.activate!

        render json: {
          status: 'activated',
          recommendation: recommendation.to_detailed_json
        }, status: :ok
      end

      # POST /api/v1/graph_rag/recommendations/:recommendation_id/feedback
      # 추천에 대한 피드백 제출
      def submit_feedback
        recommendation = LearningRecommendation.find(params[:recommendation_id])
        authorize_recommendation_access!(recommendation)

        feedback = feedback_params[:feedback]
        rating = feedback_params[:rating]

        recommendation.add_feedback(feedback, rating)

        render json: {
          status: 'feedback_recorded',
          message: '피드백이 기록되었습니다.'
        }, status: :ok
      end

      # GET /api/v1/graph_rag/analysis-history
      # 분석 이력 조회
      def analysis_history
        analyses = AnalysisResult.where(
          user_id: current_user.id,
          status: 'completed'
        ).recent.page(params[:page]).per(20)

        render json: {
          total_count: AnalysisResult.where(user_id: current_user.id).count,
          analyses: analyses.map(&:to_analysis_json),
          pagination: {
            current_page: analyses.current_page,
            total_pages: analyses.total_pages,
            per_page: analyses.limit_value
          }
        }, status: :ok
      end

      # GET /api/v1/study_sets/:study_set_id/graph_rag/statistics
      # GraphRAG 통계
      def statistics
        analyses = AnalysisResult.where(
          user_id: current_user.id,
          study_set_id: @study_set.id,
          status: 'completed'
        )

        if analyses.empty?
          return render json: {
            statistics: {
              total_analyses: 0,
              average_concept_gap: 0.0,
              most_common_error_type: 'unknown'
            }
          }, status: :ok
        end

        careless_count = analyses.where(error_type: 'careless').count
        concept_gap_count = analyses.where(error_type: 'concept_gap').count
        mixed_count = analyses.where(error_type: 'mixed').count

        most_common_error = [
          ['careless', careless_count],
          ['concept_gap', concept_gap_count],
          ['mixed', mixed_count]
        ].max_by { |_, count| count }.first

        render json: {
          statistics: {
            total_analyses: analyses.count,
            average_concept_gap: analyses.average(:concept_gap_score).round(3),
            average_confidence: analyses.average(:confidence_score).round(3),
            error_distribution: {
              careless: careless_count,
              concept_gap: concept_gap_count,
              mixed: mixed_count
            },
            most_common_error_type: most_common_error,
            high_confidence_analyses: analyses.where('confidence_score >= ?', 0.7).count,
            critical_gaps: analyses.where('concept_gap_score >= ?', 0.7).count,
            average_processing_time_ms: analyses.average(:processing_time_ms).round(0)
          }
        }, status: :ok
      end

      private

      def set_study_set
        @study_set = StudySet.find(params[:study_set_id])
      end

      def authorize_study_set_access!
        render json: { error: '접근 권한이 없습니다.' }, status: :forbidden unless @study_set.user_id == current_user.id
      end

      def authorize_analysis_access!(analysis)
        render json: { error: '접근 권한이 없습니다.' }, status: :forbidden unless analysis.user_id == current_user.id
      end

      def authorize_recommendation_access!(recommendation)
        render json: { error: '접근 권한이 없습니다.' }, status: :forbidden unless recommendation.user_id == current_user.id
      end

      def analysis_params
        params.require(:analysis).permit(:question_id, :selected_answer)
      end

      def feedback_params
        params.require(:feedback).permit(:feedback, :rating)
      end

      # 약점 개념 집계
      def aggregate_weaknesses(analyses)
        weakness_map = {}

        analyses.each do |analysis|
          related_concepts = analysis.related_concepts_with_details
          related_concepts.each do |concept|
            concept_id = concept[:concept_id]

            if weakness_map[concept_id]
              weakness_map[concept_id][:gap_score] = (weakness_map[concept_id][:gap_score] + analysis.concept_gap_score) / 2
              weakness_map[concept_id][:occurrence_count] += 1
            else
              weakness_map[concept_id] = {
                concept_id: concept_id,
                concept_name: concept[:name],
                gap_score: analysis.concept_gap_score,
                occurrence_count: 1,
                relationship_type: concept[:relationship_type]
              }
            end
          end
        end

        weakness_map.values.sort_by { |w| w[:gap_score] }.reverse.take(10)
      end

      # 추천 조치 제안
      def recommend_action(weaknesses)
        return nil if weaknesses.empty?

        critical_count = weaknesses.count { |w| w[:gap_score] > 0.7 }

        case critical_count
        when 0
          { action: 'maintenance', message: '현재 학습 상태가 양호합니다. 계속 진행하세요.' }
        when 1..3
          { action: 'focused_review', message: "#{critical_count}개의 약점을 집중 복습하세요." }
        else
          { action: 'comprehensive_review', message: '전반적인 기초 복습이 필요합니다.' }
        end
      end
    end
  end
end
