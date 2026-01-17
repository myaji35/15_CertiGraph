# app/jobs/analyze_randomization_job.rb
class AnalyzeRandomizationJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # Perform randomization analysis for a study material
  def perform(study_material_id, iterations = 100)
    study_material = StudyMaterial.find(study_material_id)

    Rails.logger.info "Starting randomization analysis for study_material_id: #{study_material_id}"

    # Create analyzer
    analyzer = RandomizationAnalyzer.new(study_material)

    # Run analysis
    analysis_results = analyzer.analyze_all_questions(iterations: iterations)

    # Save results to database
    analyzer.save_analysis_results(analysis_results)

    # Log summary
    Rails.logger.info "Completed randomization analysis for study_material_id: #{study_material_id}"
    Rails.logger.info "Overall bias score: #{analysis_results[:overall_bias_score]}"
    Rails.logger.info "Uniformity rate: #{(analysis_results[:uniformity_rate] * 100).round(1)}%"
    Rails.logger.info "Quality rating: #{analysis_results[:quality_rating]}"

    # Send notification to user if needed
    notify_user_if_significant_bias(study_material, analysis_results)

    analysis_results
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Study material not found: #{study_material_id}"
    raise e
  rescue => e
    Rails.logger.error "Error analyzing randomization for study_material_id #{study_material_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def notify_user_if_significant_bias(study_material, analysis_results)
    return unless analysis_results[:overall_bias_score] > 30

    # Notification logic here
    Rails.logger.warn "Significant bias detected in study_material_id: #{study_material.id}"
    Rails.logger.warn "Bias score: #{analysis_results[:overall_bias_score]}"

    # You can send email, push notification, or create an in-app notification
    # Example: StudyMaterialMailer.bias_alert(study_material, analysis_results).deliver_later
  end
end
