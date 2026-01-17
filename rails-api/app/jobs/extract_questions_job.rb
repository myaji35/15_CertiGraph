# Background job for extracting questions from study materials
class ExtractQuestionsJob < ApplicationJob
  queue_as :default

  # Perform question extraction
  # @param study_material_id [Integer] ID of the study material
  # @param options [Hash] Additional options
  def perform(study_material_id, options = {})
    study_material = StudyMaterial.find(study_material_id)

    Rails.logger.info("Starting question extraction for StudyMaterial##{study_material_id}")

    # Get markdown content
    markdown_content = study_material.extracted_data
    if markdown_content.blank?
      raise "No extracted data found for StudyMaterial##{study_material_id}"
    end

    # Extract questions using AI service
    service = AiQuestionExtractionService.new(markdown_content, study_material: study_material)
    extracted_data = service.extract

    unless extracted_data[:success]
      raise "Question extraction failed: #{extracted_data[:error]}"
    end

    # Save to database
    save_results = service.save_to_database(extracted_data)

    # Update study material status
    study_material.update(
      status: 'questions_extracted',
      graph_metadata: (study_material.graph_metadata || {}).merge(
        questions_extracted_at: Time.current,
        extraction_stats: extracted_data[:stats],
        save_results: save_results
      )
    )

    Rails.logger.info(
      "Question extraction completed for StudyMaterial##{study_material_id}: " \
      "#{save_results[:questions_created]} questions, #{save_results[:passages_created]} passages"
    )

    # Return results
    {
      study_material_id: study_material_id,
      extraction_stats: extracted_data[:stats],
      save_results: save_results,
      success: true
    }
  rescue StandardError => e
    Rails.logger.error("Question extraction failed for StudyMaterial##{study_material_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    # Update study material with error
    study_material&.update(
      status: 'extraction_failed',
      error_message: "Question extraction failed: #{e.message}"
    )

    raise e
  end
end
