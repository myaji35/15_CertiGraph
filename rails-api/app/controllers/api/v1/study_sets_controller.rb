module Api
  module V1
    class StudySetsController < ApplicationController
      before_action :set_study_set, only: [:show, :update, :destroy]

      def index
        study_sets = current_user.study_sets.includes(:study_materials)
        render json: study_sets.map { |set| study_set_json(set) }
      end

      def show
        render json: study_set_json(@study_set)
      end

      def create
        study_set = current_user.study_sets.build(study_set_params)

        if study_set.save
          render json: study_set_json(study_set), status: :created
        else
          render json: { errors: study_set.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def update
        if @study_set.update(study_set_params)
          render json: study_set_json(@study_set)
        else
          render json: { errors: @study_set.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def destroy
        @study_set.destroy
        head :no_content
      end

      private

      def set_study_set
        @study_set = current_user.study_sets.find(params[:id])
      end

      def study_set_params
        params.permit(:name, :description, :exam_date, :certification_id)
      end

      def study_set_json(study_set)
        {
          id: study_set.id,
          name: study_set.name,
          description: study_set.description,
          exam_date: study_set.exam_date,
          certification_id: study_set.certification_id,
          created_at: study_set.created_at,
          materials_count: study_set.study_materials.count,
          questions_count: study_set.questions.count,
          progress: calculate_progress(study_set)
        }
      end

      def calculate_progress(study_set)
        total = study_set.questions.count
        return 0 if total.zero?
        # TODO: Add user_answers relationship later
        0
      end
    end
  end
end