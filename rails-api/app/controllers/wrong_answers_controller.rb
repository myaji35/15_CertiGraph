class WrongAnswersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_wrong_answer, only: [:show, :update, :destroy, :mark_reviewed]

  # GET /wrong_answers
  def index
    @wrong_answers = current_user.wrong_answers
                                  .includes(:question, :study_set)
                                  .order(last_attempted_at: :desc)
                                  .page(params[:page])
                                  .per(20)

    # Apply filters
    if params[:study_set_id].present?
      @wrong_answers = @wrong_answers.where(study_set_id: params[:study_set_id])
    end

    if params[:reviewed].present?
      reviewed = params[:reviewed] == 'true'
      @wrong_answers = @wrong_answers.where(reviewed: reviewed)
    end

    # Group by tag if requested
    if params[:group_by] == 'tag'
      @grouped_answers = @wrong_answers.group_by { |wa| wa.tags.presence || ['미분류'] }
    end
  end

  # GET /wrong_answers/:id
  def show
    @question = @wrong_answer.question
    @study_set = @wrong_answer.study_set
  end

  # PATCH /wrong_answers/:id
  def update
    if @wrong_answer.update(wrong_answer_params)
      redirect_to @wrong_answer, notice: '오답노트가 업데이트되었습니다'
    else
      render :show
    end
  end

  # DELETE /wrong_answers/:id
  def destroy
    @wrong_answer.destroy
    redirect_to wrong_answers_path, notice: '오답노트에서 삭제되었습니다'
  end

  # POST /wrong_answers/:id/mark_reviewed
  def mark_reviewed
    @wrong_answer.update!(reviewed: true, reviewed_at: Time.current)

    respond_to do |format|
      format.html { redirect_to wrong_answers_path, notice: '복습 완료로 표시되었습니다' }
      format.json { render json: { success: true } }
    end
  end

  # POST /wrong_answers/:id/add_tag
  def add_tag
    @wrong_answer = current_user.wrong_answers.find(params[:id])
    tag = params[:tag]

    if tag.present?
      tags = @wrong_answer.tags || []
      tags << tag unless tags.include?(tag)
      @wrong_answer.update!(tags: tags)

      render json: { success: true, tags: tags }
    else
      render json: { success: false, error: '태그를 입력해주세요' }, status: :unprocessable_entity
    end
  end

  # DELETE /wrong_answers/:id/remove_tag
  def remove_tag
    @wrong_answer = current_user.wrong_answers.find(params[:id])
    tag = params[:tag]

    tags = @wrong_answer.tags || []
    tags.delete(tag)
    @wrong_answer.update!(tags: tags)

    render json: { success: true, tags: tags }
  end

  private

  def set_wrong_answer
    @wrong_answer = current_user.wrong_answers.find(params[:id])
  end

  def wrong_answer_params
    params.require(:wrong_answer).permit(:notes, :reviewed, tags: [])
  end
end
