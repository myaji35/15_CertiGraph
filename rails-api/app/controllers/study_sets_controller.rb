class StudySetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_set, only: [:show, :edit, :update, :destroy]

  def index
    @study_sets = current_user.study_sets.order(created_at: :desc)
  end

  def show
    @study_materials = @study_set.study_materials.order(created_at: :desc)
  end

  def new
    @study_set = current_user.study_sets.build
  end

  def create
    @study_set = current_user.study_sets.build(study_set_params)

    if @study_set.save
      redirect_to @study_set, notice: '학습 세트가 성공적으로 생성되었습니다.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @study_set.update(study_set_params)
      redirect_to @study_set, notice: '학습 세트가 성공적으로 업데이트되었습니다.'
    else
      render :edit
    end
  end

  def destroy
    @study_set.destroy
    redirect_to study_sets_path, notice: '학습 세트가 삭제되었습니다.'
  end

  private

  def set_study_set
    @study_set = current_user.study_sets.find(params[:id])
  end

  def study_set_params
    params.require(:study_set).permit(:title, :description, :certification)
  end
end