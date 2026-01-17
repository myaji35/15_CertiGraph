# StudyMaterialsController - CRUD for study materials
class StudyMaterialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_set, except: [:upload_form]
  before_action :set_study_material, only: [:show, :edit, :update, :destroy, :reprocess, :export]

  # GET /study-materials/upload (Epic 2 Test Compatibility)
  def upload_form
    @study_sets = current_user.study_sets if current_user
  end

  # GET /study_sets/:study_set_id/study_materials
  def index
    @study_materials = @study_set.study_materials
                                  .order(created_at: :desc)

    respond_to do |format|
      format.html
      format.json { render json: @study_materials }
    end
  end

  # GET /study_sets/:study_set_id/study_materials/:id
  def show
    @questions = @study_material.questions
    @knowledge_nodes = @study_material.knowledge_nodes
                                      .order(importance: :desc)
                                      .limit(10)
    @extraction_stats = @study_material.graph_metadata&.dig('extraction_stats') || {}

    respond_to do |format|
      format.html
      format.json { render json: study_material_json(@study_material) }
    end
  end

  # GET /study_sets/:study_set_id/study_materials/new
  def new
    @study_material = @study_set.study_materials.build
  end

  # GET /study_sets/:study_set_id/study_materials/:id/edit
  def edit
  end

  # POST /study_sets/:study_set_id/study_materials
  def create
    @study_material = @study_set.study_materials.build(study_material_params)
    @study_material.status = 'pending'

    if @study_material.save
      # Start processing if file attached
      if @study_material.pdf_file.attached?
        ProcessPdfJob.perform_later(@study_material.id)
      end

      respond_to do |format|
        format.html do
          redirect_to study_set_study_material_path(@study_set, @study_material),
                      notice: '학습 자료가 생성되었습니다.'
        end
        format.json do
          render json: { success: true, study_material: study_material_json(@study_material) },
                 status: :created
        end
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json do
          render json: { success: false, errors: @study_material.errors.full_messages },
                 status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH /study_sets/:study_set_id/study_materials/:id
  def update
    if @study_material.update(study_material_params)
      respond_to do |format|
        format.html do
          redirect_to study_set_study_material_path(@study_set, @study_material),
                      notice: '학습 자료가 업데이트되었습니다.'
        end
        format.json do
          render json: { success: true, study_material: study_material_json(@study_material) }
        end
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json do
          render json: { success: false, errors: @study_material.errors.full_messages },
                 status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /study_sets/:study_set_id/study_materials/:id
  def destroy
    @study_material.destroy

    respond_to do |format|
      format.html do
        redirect_to study_set_study_materials_path(@study_set),
                    notice: '학습 자료가 삭제되었습니다.'
      end
      format.json { render json: { success: true } }
    end
  end

  # POST /study_sets/:study_set_id/study_materials/:id/reprocess
  def reprocess
    @study_material.update!(status: 'pending')
    ProcessPdfJob.perform_later(@study_material.id)

    respond_to do |format|
      format.html do
        redirect_to study_set_study_material_path(@study_set, @study_material),
                    notice: '재처리가 시작되었습니다.'
      end
      format.json { render json: { success: true, message: 'Reprocessing started' } }
    end
  end

  # POST /study_sets/:study_set_id/study_materials/:id/extract_concepts
  def extract_concepts
    ExtractConceptsJob.perform_later(@study_material.id)

    respond_to do |format|
      format.html do
        redirect_to study_set_study_material_path(@study_set, @study_material),
                    notice: '개념 추출이 시작되었습니다.'
      end
      format.json { render json: { success: true, message: 'Concept extraction started' } }
    end
  end

  # GET /study_sets/:study_set_id/study_materials/:id/export
  def export
    format = params[:format] || 'json'

    case format
    when 'json'
      send_data @study_material.to_json(include: [:questions, :passages]),
                filename: "#{@study_material.name}_#{Date.today}.json",
                type: 'application/json'
    when 'csv'
      csv_data = generate_csv_export
      send_data csv_data,
                filename: "#{@study_material.name}_questions_#{Date.today}.csv",
                type: 'text/csv'
    else
      render json: { error: 'Invalid format' }, status: :bad_request
    end
  end

  # GET /study_sets/:study_set_id/study_materials/:id/processing_status
  def processing_status
    status = {
      status: @study_material.status,
      progress: @study_material.parsing_progress || 0,
      questions_count: @study_material.questions.count,
      passages_count: @study_material.passages.count,
      concepts_count: @study_material.knowledge_nodes.count,
      error_message: @study_material.error_message
    }

    render json: status
  end

  private

  def set_study_set
    @study_set = current_user.study_sets.find(params[:study_set_id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html do
        redirect_to root_path, alert: '스터디 세트를 찾을 수 없습니다.'
      end
      format.json { render json: { error: 'Study set not found' }, status: :not_found }
    end
  end

  def set_study_material
    @study_material = @study_set.study_materials.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html do
        redirect_to study_set_study_materials_path(@study_set),
                    alert: '학습 자료를 찾을 수 없습니다.'
      end
      format.json { render json: { error: 'Study material not found' }, status: :not_found }
    end
  end

  def study_material_params
    params.require(:study_material).permit(
      :name,
      :description,
      :category,
      :difficulty_level,
      :pdf_file,
      :is_public,
      :price,
      :certification_name,
      :exam_year
    )
  end

  def study_material_json(material)
    {
      id: material.id,
      name: material.name,
      status: material.status,
      status_display: material.status_display,
      file_name: material.file_name,
      questions_count: material.total_questions,
      passages_count: material.passages.count,
      concepts_count: material.knowledge_nodes.count,
      parsing_progress: material.parsing_progress,
      created_at: material.created_at,
      updated_at: material.updated_at,
      pdf_attached: material.pdf_file.attached?
    }
  end

  def generate_csv_export
    require 'csv'

    CSV.generate(headers: true) do |csv|
      csv << ['Question Number', 'Content', 'Answer', 'Difficulty', 'Chapter', 'Topic']

      @study_material.questions.find_each do |question|
        csv << [
          question.question_number,
          question.content,
          question.answer,
          question.difficulty,
          question.chapter,
          question.topic
        ]
      end
    end
  end
end
