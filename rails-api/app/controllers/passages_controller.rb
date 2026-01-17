class PassagesController < ApplicationController
  before_action :set_study_material
  before_action :set_passage, only: [:show, :update, :destroy]

  # GET /study_materials/:study_material_id/passages
  def index
    @passages = @study_material.passages.by_position

    # Apply filters
    @passages = @passages.with_images if params[:with_images] == 'true'
    @passages = @passages.with_tables if params[:with_tables] == 'true'

    render json: {
      passages: @passages.map { |p| passage_json(p) },
      total: @passages.count
    }
  end

  # GET /passages/:id
  def show
    render json: passage_json(@passage, include_questions: true)
  end

  # POST /study_materials/:study_material_id/passages
  def create
    @passage = @study_material.passages.new(passage_params)

    if @passage.save
      render json: passage_json(@passage), status: :created
    else
      render json: { errors: @passage.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /passages/:id
  def update
    if @passage.update(passage_params)
      render json: passage_json(@passage)
    else
      render json: { errors: @passage.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /passages/:id
  def destroy
    @passage.destroy
    head :no_content
  end

  private

  def set_study_material
    @study_material = StudyMaterial.find(params[:study_material_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Study material not found" }, status: :not_found
  end

  def set_passage
    @passage = Passage.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Passage not found" }, status: :not_found
  end

  def passage_params
    params.require(:passage).permit(
      :content,
      :passage_type,
      :position,
      :has_image,
      :has_table,
      :summary,
      metadata: {}
    )
  end

  def passage_json(passage, include_questions: false)
    result = {
      id: passage.id,
      content: passage.content,
      passage_type: passage.passage_type,
      position: passage.position,
      has_image: passage.has_image,
      has_table: passage.has_table,
      character_count: passage.character_count,
      summary: passage.summary,
      metadata: passage.metadata,
      created_at: passage.created_at,
      updated_at: passage.updated_at
    }

    if include_questions
      result[:questions] = passage.questions.map do |q|
        {
          id: q.id,
          question_number: q.question_number,
          content: q.content.truncate(100),
          question_type: q.question_type
        }
      end
      result[:primary_questions] = passage.primary_questions.map(&:id)
    end

    result
  end
end
