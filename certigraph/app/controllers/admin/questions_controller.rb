# frozen_string_literal: true

module Admin
  class QuestionsController < ApplicationController
    before_action :authenticate_admin!
    before_action :set_question, only: [:show, :edit, :update, :destroy]
    before_action :set_study_set, only: [:new, :create]

    # GET /admin/questions
    def index
      @questions = Question.includes(:study_set).order(created_at: :desc).page(params[:page])
      @total_count = Question.count
    end

    # GET /admin/questions/:id
    def show
    end

    # GET /admin/questions/new
    def new
      @question = @study_set.questions.build
      4.times { @question.options.build }
    end

    # GET /admin/questions/:id/edit
    def edit
      # Ensure we have at least 4 options
      (4 - @question.options.size).times { @question.options.build } if @question.options.size < 4
    end

    # POST /admin/questions
    def create
      @question = @study_set.questions.build(question_params)

      if @question.save
        redirect_to admin_study_set_path(@study_set), notice: '문제가 성공적으로 생성되었습니다.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /admin/questions/:id
    def update
      if @question.update(question_params)
        redirect_to admin_question_path(@question), notice: '문제가 성공적으로 수정되었습니다.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin/questions/:id
    def destroy
      study_set = @question.study_set
      @question.destroy
      redirect_to admin_study_set_path(study_set), notice: '문제가 삭제되었습니다.'
    end

    # POST /admin/questions/bulk_import
    def bulk_import
      file = params[:file]
      
      unless file.present?
        redirect_to admin_questions_path, alert: 'CSV 파일을 선택해주세요.'
        return
      end

      begin
        imported_count = Question.import_from_csv(file.path)
        redirect_to admin_questions_path, notice: "#{imported_count}개의 문제가 성공적으로 추가되었습니다."
      rescue StandardError => e
        redirect_to admin_questions_path, alert: "CSV 가져오기 실패: #{e.message}"
      end
    end

    private

    def set_question
      @question = Question.find(params[:id])
    end

    def set_study_set
      @study_set = StudySet.find(params[:study_set_id])
    end

    def question_params
      params.require(:question).permit(
        :content,
        :question_type,
        :difficulty,
        :topic,
        :explanation,
        :correct_answer,
        options_attributes: [:id, :content, :is_correct, :_destroy]
      )
    end

    def authenticate_admin!
      # TODO: Implement proper admin authentication
      # For MVP, we'll use a simple check
      unless current_user&.admin?
        redirect_to root_path, alert: '관리자 권한이 필요합니다.'
      end
    end
  end
end
