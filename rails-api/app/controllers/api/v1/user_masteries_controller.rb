module Api
  module V1
    class UserMasteriesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_knowledge_node, only: [:show, :update]

      # GET /api/v1/knowledge_nodes/:knowledge_node_id/mastery
      def show
        mastery = UserMastery.find_by(user_id: current_user.id, knowledge_node_id: @knowledge_node.id)

        if mastery
          render json: {
            success: true,
            data: mastery.to_json
          }
        else
          render json: {
            success: false,
            message: 'Mastery record not found'
          }, status: :not_found
        end
      end

      # PUT /api/v1/knowledge_nodes/:knowledge_node_id/mastery
      def update
        mastery = UserMastery.find_or_create_by(
          user_id: current_user.id,
          knowledge_node_id: @knowledge_node.id
        )

        correct = params.dig(:attempt, :correct) == true
        time_minutes = params.dig(:attempt, :time_minutes) || 0

        mastery.update_with_attempt(correct: correct, time_minutes: time_minutes)

        render json: {
          success: true,
          data: mastery.to_json
        }
      end

      # GET /api/v1/study_materials/:study_material_id/masteries
      def study_material_masteries
        study_material = StudyMaterial.find(params[:study_material_id])
        authorize_material_access(study_material)

        masteries = UserMastery.where(user_id: current_user.id)
                              .joins(:knowledge_node)
                              .where(knowledge_nodes: { study_material_id: study_material.id })
                              .page(params[:page])
                              .per(params[:per_page] || 20)

        render json: {
          success: true,
          data: masteries.map(&:to_json),
          pagination: {
            current_page: masteries.current_page,
            total_pages: masteries.total_pages,
            total_count: masteries.total_count
          }
        }
      end

      # GET /api/v1/masteries/by_status/:status
      def by_status
        status = params[:status]
        allowed_statuses = %w(untested learning mastered weak)

        unless allowed_statuses.include?(status)
          return render json: {
            success: false,
            message: "Invalid status. Must be one of: #{allowed_statuses.join(', ')}"
          }, status: :bad_request
        end

        masteries = UserMastery.where(user_id: current_user.id, status: status)
                              .page(params[:page])
                              .per(params[:per_page] || 20)

        render json: {
          success: true,
          data: masteries.map(&:to_json),
          pagination: {
            current_page: masteries.current_page,
            total_pages: masteries.total_pages,
            total_count: masteries.total_count
          }
        }
      end

      # GET /api/v1/masteries/weak_areas
      def weak_areas
        masteries = UserMastery.where(user_id: current_user.id, color: 'red')
                              .order(mastery_level: :asc)
                              .page(params[:page])
                              .per(params[:per_page] || 20)

        render json: {
          success: true,
          data: masteries.map(&:to_json),
          pagination: {
            current_page: masteries.current_page,
            total_pages: masteries.total_pages,
            total_count: masteries.total_count
          }
        }
      end

      # GET /api/v1/masteries/strong_areas
      def strong_areas
        masteries = UserMastery.where(user_id: current_user.id, color: 'green')
                              .order(mastery_level: :desc)
                              .page(params[:page])
                              .per(params[:per_page] || 20)

        render json: {
          success: true,
          data: masteries.map(&:to_json),
          pagination: {
            current_page: masteries.current_page,
            total_pages: masteries.total_pages,
            total_count: masteries.total_count
          }
        }
      end

      # GET /api/v1/masteries/statistics
      def statistics
        masteries = UserMastery.where(user_id: current_user.id)

        total_count = masteries.count
        mastered_count = masteries.where(color: 'green').count
        learning_count = masteries.where(color: 'yellow').count
        weak_count = masteries.where(color: 'red').count
        untested_count = masteries.where(color: 'gray').count

        avg_mastery = total_count > 0 ? masteries.average(:mastery_level).round(3) : 0
        avg_accuracy = total_count > 0 ? masteries.average('correct_attempts::float / attempts').round(1) : 0
        total_time_minutes = masteries.sum(:total_time_minutes)

        render json: {
          success: true,
          data: {
            total_concepts: total_count,
            mastered: mastered_count,
            learning: learning_count,
            weak: weak_count,
            untested: untested_count,
            avg_mastery_level: avg_mastery,
            avg_accuracy: avg_accuracy,
            total_study_time_hours: (total_time_minutes / 60.0).round(1),
            progress_percentage: total_count > 0 ? ((mastered_count.to_f / total_count) * 100).round(1) : 0
          }
        }
      end

      private

      def set_knowledge_node
        @knowledge_node = KnowledgeNode.find(params[:knowledge_node_id])
        authorize_node_access
      end

      def authorize_node_access
        unless current_user.study_sets.find_by(id: @knowledge_node.study_material.study_set_id)
          render json: { success: false, message: 'Unauthorized' }, status: :forbidden
        end
      end

      def authorize_material_access(study_material)
        unless current_user.study_sets.find_by(id: study_material.study_set_id)
          render json: { success: false, message: 'Unauthorized' }, status: :forbidden
        end
      end
    end
  end
end
