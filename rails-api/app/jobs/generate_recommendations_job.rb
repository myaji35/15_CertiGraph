# app/jobs/generate_recommendations_job.rb
class GenerateRecommendationsJob < ApplicationJob
  queue_as :default

  # Generate recommendations for a specific user and study set
  def perform(user_id, study_set_id, options = {})
    user = User.find(user_id)
    study_set = StudySet.find(study_set_id)

    algorithm = options[:algorithm] || 'hybrid'
    limit = options[:limit] || 10

    Rails.logger.info "Generating #{algorithm} recommendations for user #{user_id}, study_set #{study_set_id}"

    recommendations = case algorithm
                     when 'collaborative_filtering'
                       generate_cf_recommendations(user, study_set, limit)
                     when 'content_based'
                       generate_cb_recommendations(user, study_set, limit)
                     when 'hybrid'
                       generate_hybrid_recommendations(user, study_set, limit)
                     when 'ensemble'
                       generate_ensemble_recommendations(user, study_set, limit)
                     else
                       generate_hybrid_recommendations(user, study_set, limit)
                     end

    # Store recommendations
    store_recommendations(user, study_set, recommendations, algorithm)

    Rails.logger.info "Generated #{recommendations.size} recommendations for user #{user_id}"

    recommendations
  rescue StandardError => e
    Rails.logger.error "Failed to generate recommendations: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  private

  def generate_cf_recommendations(user, study_set, limit)
    service = CollaborativeFilteringService.new(user, study_set)
    service.hybrid_cf_recommendations(limit: limit)
  end

  def generate_cb_recommendations(user, study_set, limit)
    service = ContentBasedFilteringService.new(user, study_set)
    service.generate_recommendations(limit: limit)
  end

  def generate_hybrid_recommendations(user, study_set, limit)
    service = HybridRecommendationService.new(user, study_set)
    service.generate_recommendations(limit: limit)
  end

  def generate_ensemble_recommendations(user, study_set, limit)
    service = HybridRecommendationService.new(user, study_set)
    service.ensemble_recommendations(limit: limit)
  end

  def store_recommendations(user, study_set, recommendations, algorithm)
    recommendations.each do |rec|
      # Check if question exists
      question = Question.find_by(id: rec[:question_id])
      next unless question

      # Create learning recommendation
      learning_rec = LearningRecommendation.create!(
        user: user,
        study_set: study_set,
        recommendation_type: determine_recommendation_type(rec),
        recommendation_algorithm: algorithm,
        status: 'pending',
        recommended_questions: [{ question_id: rec[:question_id] }],
        total_recommended_count: 1,
        priority_level: calculate_priority(rec[:score]),
        cf_score: rec[:metadata]&.dig(:cf_score),
        cb_score: rec[:metadata]&.dig(:cb_score),
        confidence_level: rec[:confidence] || 0.7,
        explanation_text: rec[:reason],
        algorithm_version: '1.0',
        personalization_params: rec[:metadata]
      )

      Rails.logger.debug "Created recommendation #{learning_rec.id} for question #{rec[:question_id]}"
    end
  end

  def determine_recommendation_type(recommendation)
    reason = recommendation[:reason].to_s.downcase

    if reason.include?('약점') || reason.include?('weak')
      'remedial'
    elsif reason.include?('다음') || reason.include?('progressive')
      'progressive'
    else
      'comprehensive'
    end
  end

  def calculate_priority(score)
    case score
    when 80..Float::INFINITY then 10
    when 60...80 then 8
    when 40...60 then 6
    when 20...40 then 4
    else 2
    end
  end
end
