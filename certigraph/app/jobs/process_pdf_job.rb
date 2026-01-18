# frozen_string_literal: true

class ProcessPdfJob < ApplicationJob
  queue_as :default

  def perform(study_material_id)
    study_material = StudyMaterial.find(study_material_id)
    
    # Update status
    study_material.update!(processing_status: 'processing')

    begin
      # Step 1: Extract text from PDF using Upstage OCR
      Rails.logger.info "Starting OCR for StudyMaterial ##{study_material_id}"
      ocr_service = UpstageOcrService.new
      ocr_result = ocr_service.extract_text(study_material.pdf_file.path)
      
      extracted_text = ocr_result[:text]
      page_count = ocr_result[:metadata][:page_count]

      # Update study material with metadata
      study_material.update!(
        page_count: page_count,
        extracted_text: extracted_text
      )

      # Step 2: Extract questions using GPT-4o
      Rails.logger.info "Extracting questions for StudyMaterial ##{study_material_id}"
      extractor_service = QuestionExtractorService.new
      questions = extractor_service.extract_questions(extracted_text, study_material.study_set_id)

      # Step 3: Update status
      study_material.update!(
        processing_status: 'completed',
        questions_count: questions.count,
        processed_at: Time.current
      )

      # Step 4: Notify user
      UserMailer.pdf_processing_complete(study_material.user, study_material, questions.count).deliver_later

      Rails.logger.info "Successfully processed StudyMaterial ##{study_material_id}: #{questions.count} questions created"

    rescue StandardError => e
      Rails.logger.error "PDF processing failed for StudyMaterial ##{study_material_id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      study_material.update!(
        processing_status: 'failed',
        error_message: e.message
      )

      # Notify user of failure
      UserMailer.pdf_processing_failed(study_material.user, study_material, e.message).deliver_later

      raise e
    end
  end
end
