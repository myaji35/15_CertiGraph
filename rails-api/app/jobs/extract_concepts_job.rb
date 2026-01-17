class ExtractConceptsJob < ApplicationJob
  queue_as :default

  # Job to extract concepts from study material questions
  def perform(study_material_id)
    study_material = StudyMaterial.find(study_material_id)

    Rails.logger.info("Starting concept extraction for study material #{study_material_id}")

    service = ConceptExtractionService.new(study_material)
    result = service.extract_from_all_questions

    # Update study material metadata
    study_material.update(
      graph_metadata: (study_material.graph_metadata || {}).merge({
        concepts_extracted: true,
        concepts_extracted_at: Time.current,
        extraction_result: result
      })
    )

    # Normalize concepts after extraction
    normalize_service = ConceptNormalizationService.new(study_material)
    normalization_result = normalize_service.normalize_all_concepts

    study_material.update(
      graph_metadata: study_material.graph_metadata.merge({
        concepts_normalized: true,
        concepts_normalized_at: Time.current,
        normalization_result: normalization_result
      })
    )

    Rails.logger.info("Concept extraction completed for study material #{study_material_id}: #{result}")

    result
  rescue StandardError => e
    Rails.logger.error("Concept extraction failed for study material #{study_material_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    study_material.update(
      graph_error: "Concept extraction failed: #{e.message}",
      graph_metadata: (study_material.graph_metadata || {}).merge({
        concepts_extracted: false,
        last_extraction_error: e.message,
        last_extraction_attempt: Time.current
      })
    )

    raise e
  end
end
