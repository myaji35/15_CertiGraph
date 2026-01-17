class AnalyzePrerequisitesJob < ApplicationJob
  queue_as :default

  # Retry configuration
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(study_material_id)
    study_material = StudyMaterial.find(study_material_id)

    Rails.logger.info "[AnalyzePrerequisitesJob] Starting prerequisite analysis for study_material_id=#{study_material_id}"

    service = PrerequisiteAnalysisService.new(study_material)

    # Analyze all prerequisites
    results = service.analyze_all_prerequisites

    # Update study material metadata
    study_material.update!(
      graph_metadata: (study_material.graph_metadata || {}).merge(
        prerequisite_analysis: {
          last_analyzed_at: Time.current,
          total_nodes: results[:total_nodes],
          analyzed_nodes: results[:analyzed],
          relationships_created: results[:relationships_created],
          errors_count: results[:errors].size,
          status: 'completed'
        }
      )
    )

    Rails.logger.info "[AnalyzePrerequisitesJob] Completed: analyzed #{results[:analyzed]} nodes, " \
                      "created #{results[:relationships_created]} relationships"

    # Send notification if there were errors
    if results[:errors].any?
      Rails.logger.warn "[AnalyzePrerequisitesJob] Errors occurred: #{results[:errors].size} errors"
    end

    results
  rescue => e
    Rails.logger.error "[AnalyzePrerequisitesJob] Failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    # Update study material with error status
    study_material = StudyMaterial.find_by(id: study_material_id)
    if study_material
      study_material.update!(
        graph_metadata: (study_material.graph_metadata || {}).merge(
          prerequisite_analysis: {
            last_analyzed_at: Time.current,
            status: 'failed',
            error_message: e.message
          }
        )
      )
    end

    raise e
  end
end
