class QuestionsController < ApplicationController
  before_action :set_study_material, only: [:index, :create, :extract, :batch_create]
  before_action :set_question, only: [:show, :update, :destroy, :validate_question]

  # GET /study_materials/:study_material_id/questions
  def index
    @questions = @study_material.questions
                                .includes(:passages, :question_passages)
                                .order(:question_number)

    # Apply filters
    @questions = @questions.by_type(params[:question_type]) if params[:question_type].present?
    @questions = @questions.by_difficulty(params[:difficulty]) if params[:difficulty].present?
    @questions = @questions.validated if params[:validated] == 'true'
    @questions = @questions.with_passages if params[:with_passages] == 'true'

    # Pagination
    page = params[:page] || 1
    per_page = params[:per_page] || 20
    @questions = @questions.page(page).per(per_page)

    render json: {
      questions: @questions.map { |q| question_json(q) },
      meta: pagination_meta(@questions)
    }
  end

  # GET /questions/:id
  def show
    render json: question_json(@question, include_details: true)
  end

  # POST /study_materials/:study_material_id/questions
  def create
    @question = @study_material.questions.new(question_params)

    if @question.save
      @question.validate_question! if params[:auto_validate]
      render json: question_json(@question), status: :created
    else
      render json: { errors: @question.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /study_materials/:study_material_id/questions/batch_create
  def batch_create
    questions_data = params[:questions] || []
    results = { created: [], failed: [] }

    ActiveRecord::Base.transaction do
      questions_data.each do |question_data|
        question = @study_material.questions.new(
          question_number: question_data[:question_number],
          content: question_data[:content],
          options: question_data[:options],
          answer: question_data[:answer],
          explanation: question_data[:explanation],
          question_type: question_data[:question_type] || 'multiple_choice',
          difficulty: question_data[:difficulty],
          has_image: question_data[:has_image],
          has_table: question_data[:has_table]
        )

        if question.save
          question.validate_question!
          results[:created] << question_json(question)
        else
          results[:failed] << {
            data: question_data,
            errors: question.errors.full_messages
          }
        end
      end
    end

    render json: results, status: :created
  end

  # POST /study_materials/:study_material_id/questions/extract
  def extract
    markdown_content = params[:markdown_content] || @study_material.extracted_data

    if markdown_content.blank?
      return render json: { error: "No content to extract" }, status: :unprocessable_entity
    end

    # Use AI extraction service
    service = AiQuestionExtractionService.new(markdown_content, study_material: @study_material)
    extracted_data = service.extract

    if extracted_data[:success]
      # Save to database
      save_results = service.save_to_database(extracted_data)

      render json: {
        success: true,
        extraction_stats: extracted_data[:stats],
        save_results: save_results,
        questions: extracted_data[:questions].map { |q| q.slice(:question_number, :content, :answer) },
        passages: extracted_data[:passages].map { |p| p.slice(:id, :position, :character_count) }
      }
    else
      render json: {
        success: false,
        error: extracted_data[:error]
      }, status: :unprocessable_entity
    end
  end

  # PATCH /questions/:id
  def update
    if @question.update(question_params)
      @question.validate_question! if params[:auto_validate]
      render json: question_json(@question)
    else
      render json: { errors: @question.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /questions/:id
  def destroy
    @question.destroy
    head :no_content
  end

  # POST /questions/:id/validate
  def validate_question
    if @question.validate_question!
      render json: {
        success: true,
        validation_status: @question.validation_status,
        validation_errors: @question.validation_errors
      }
    else
      render json: {
        success: false,
        validation_status: @question.validation_status,
        validation_errors: @question.validation_errors
      }, status: :unprocessable_entity
    end
  end

  # POST /study_materials/:study_material_id/questions/validate_all
  def validate_all
    validation_service = QuestionValidationService.new
    questions = @study_material.questions

    results = questions.map do |question|
      validation = validation_service.validate_question_model(question)
      question.update(
        validation_status: validation[:valid] ? 'validated' : 'failed',
        validation_errors: { errors: validation[:errors], warnings: validation[:warnings] }
      )
      { id: question.id, validation: validation }
    end

    render json: {
      total: questions.count,
      validated: results.count { |r| r[:validation][:valid] },
      failed: results.count { |r| !r[:validation][:valid] },
      results: results
    }
  end

  # GET /study_materials/:study_material_id/questions/stats
  def stats
    questions = @study_material.questions

    render json: {
      total_questions: questions.count,
      by_type: questions.group(:question_type).count,
      by_difficulty: questions.group(:difficulty).count,
      by_validation_status: questions.group(:validation_status).count,
      with_passages: questions.with_passages.count,
      without_passages: questions.without_passages.count,
      validated: questions.validated.count,
      avg_confidence: questions.average(:ai_confidence_score)&.round(2) || 0
    }
  end

  # GET /questions/search
  def search
    query = params[:query]
    return render json: { questions: [] } if query.blank?

    @questions = Question.where("content LIKE ?", "%#{query}%")
                        .or(Question.where("explanation LIKE ?", "%#{query}%"))
                        .limit(50)

    render json: { questions: @questions.map { |q| question_json(q) } }
  end

  # GET /questions/by_material/:material_id
  def by_material
    study_material = StudyMaterial.find(params[:material_id])
    @questions = study_material.questions
                               .includes(:passages, :question_passages)
                               .order(:question_number)

    # Apply filters
    @questions = @questions.by_type(params[:question_type]) if params[:question_type].present?
    @questions = @questions.by_difficulty(params[:difficulty]) if params[:difficulty].present?
    @questions = @questions.validated if params[:validated] == 'true'

    render json: {
      study_material_id: study_material.id,
      total_questions: @questions.count,
      questions: @questions.map { |q| question_json(q) }
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Study material not found" }, status: :not_found
  end

  # POST /questions/:id/add_passage
  def add_passage
    passage = Passage.find(params[:passage_id])

    @question.add_passage(
      passage,
      is_primary: params[:is_primary] || false,
      relevance_score: params[:relevance_score] || 100
    )

    render json: {
      success: true,
      question: question_json(@question, include_details: true)
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Passage not found" }, status: :not_found
  end

  # DELETE /questions/:id/remove_passage/:passage_id
  def remove_passage
    passage = Passage.find(params[:passage_id])
    question_passage = @question.question_passages.find_by(passage: passage)

    if question_passage
      question_passage.destroy
      render json: { success: true }
    else
      render json: { error: "Passage not linked to this question" }, status: :not_found
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Passage not found" }, status: :not_found
  end

  private

  def set_study_material
    @study_material = StudyMaterial.find(params[:study_material_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Study material not found" }, status: :not_found
  end

  def set_question
    @question = Question.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Question not found" }, status: :not_found
  end

  def question_params
    params.require(:question).permit(
      :question_number,
      :content,
      :answer,
      :explanation,
      :question_type,
      :difficulty,
      :has_image,
      :has_table,
      :validation_status,
      :ai_confidence_score,
      options: {},
      validation_errors: {},
      extraction_metadata: {}
    )
  end

  def question_json(question, include_details: false)
    result = {
      id: question.id,
      question_number: question.question_number,
      content: question.content,
      options: question.options,
      answer: question.answer,
      explanation: question.explanation,
      question_type: question.question_type,
      difficulty: question.difficulty,
      has_image: question.has_image,
      has_table: question.has_table,
      validation_status: question.validation_status,
      ai_confidence_score: question.ai_confidence_score,
      created_at: question.created_at,
      updated_at: question.updated_at
    }

    if include_details
      result.merge!(
        passages: question.passages.map { |p| passage_json(p) },
        primary_passage: question.primary_passage ? passage_json(question.primary_passage) : nil,
        validation_errors: question.validation_errors,
        extraction_metadata: question.extraction_metadata,
        study_material_id: question.study_material_id
      )
    end

    result
  end

  def passage_json(passage)
    {
      id: passage.id,
      content: passage.content.truncate(200),
      passage_type: passage.passage_type,
      position: passage.position,
      has_image: passage.has_image,
      has_table: passage.has_table,
      character_count: passage.character_count
    }
  end

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end
end
