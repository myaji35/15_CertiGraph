# Background job for processing large file uploads
class ProcessLargeFileJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(study_material_id)
    @study_material = StudyMaterial.find(study_material_id)

    Rails.logger.info("Processing large file for material #{study_material_id}")

    # Update status
    @study_material.update!(
      status: 'processing',
      parsing_progress: 0
    )

    # Step 1: Validate uploaded file
    validate_uploaded_file!

    # Step 2: Extract PDF content
    extract_pdf_content!

    # Step 3: Process images (if any)
    process_images!

    # Step 4: Extract questions
    extract_questions!

    # Step 5: Generate embeddings
    generate_embeddings!

    # Step 6: Build knowledge graph
    build_knowledge_graph!

    # Mark as completed
    @study_material.update!(
      status: 'completed',
      parsing_progress: 100,
      last_accessed_at: Time.current
    )

    Rails.logger.info("Successfully processed material #{study_material_id}")

    # Broadcast completion via ActionCable
    broadcast_completion

  rescue StandardError => e
    handle_error(e)
    raise
  end

  private

  def validate_uploaded_file!
    unless @study_material.pdf_file.attached?
      raise StandardError, "No file attached"
    end

    # Download file to temp location for validation
    temp_file = download_to_temp

    begin
      validator = FileValidationService.new(temp_file.path)
      validator.validate!

      unless validator.errors.empty?
        raise FileValidationService::ValidationError, validator.errors.join(', ')
      end

      # Update checksum if not already set
      if @study_material.file_checksum.blank?
        checksum = validator.calculate_checksum
        @study_material.update_column(:file_checksum, checksum)
      end

      update_progress(10, "File validation completed")
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def extract_pdf_content!
    update_progress(20, "Extracting PDF content...")

    service = PdfProcessingService.new(@study_material)
    service.process

    update_progress(40, "PDF content extracted")
  end

  def process_images!
    update_progress(50, "Processing images...")

    service = ImageExtractionService.new(@study_material)
    service.extract_and_caption_images

    update_progress(60, "Images processed")
  end

  def extract_questions!
    update_progress(65, "Extracting questions...")

    service = AiQuestionExtractionService.new(@study_material)
    service.extract_questions

    update_progress(80, "Questions extracted")
  end

  def generate_embeddings!
    update_progress(85, "Generating embeddings...")

    # Generate embeddings for questions
    @study_material.questions.find_each do |question|
      next if question.embedding.present?

      EmbeddingService.new(question).generate_embedding
    end

    update_progress(90, "Embeddings generated")
  end

  def build_knowledge_graph!
    update_progress(92, "Building knowledge graph...")

    service = KnowledgeGraphService.new(@study_material)
    service.build_graph

    update_progress(95, "Knowledge graph built")
  end

  def update_progress(percentage, message = nil)
    @study_material.update_column(:parsing_progress, percentage)

    if message
      Rails.logger.info("Material #{@study_material.id}: #{message} (#{percentage}%)")
    end

    # Broadcast progress via ActionCable
    broadcast_progress(percentage, message)
  end

  def broadcast_progress(percentage, message)
    ActionCable.server.broadcast(
      "study_material_#{@study_material.id}",
      {
        type: 'progress',
        study_material_id: @study_material.id,
        progress: percentage,
        message: message,
        status: @study_material.status
      }
    )
  end

  def broadcast_completion
    ActionCable.server.broadcast(
      "study_material_#{@study_material.id}",
      {
        type: 'completed',
        study_material_id: @study_material.id,
        status: 'completed',
        questions_count: @study_material.questions.count,
        message: 'Processing completed successfully'
      }
    )
  end

  def handle_error(error)
    Rails.logger.error("ProcessLargeFileJob error: #{error.message}\n#{error.backtrace.join("\n")}")

    @study_material.update!(
      status: 'failed',
      upload_error: error.message
    )

    # Broadcast error via ActionCable
    ActionCable.server.broadcast(
      "study_material_#{@study_material.id}",
      {
        type: 'error',
        study_material_id: @study_material.id,
        status: 'failed',
        error: error.message
      }
    )
  end

  def download_to_temp
    temp_file = Tempfile.new(['upload', '.pdf'])

    @study_material.pdf_file.download do |chunk|
      temp_file.write(chunk)
    end

    temp_file.rewind
    temp_file
  end
end
