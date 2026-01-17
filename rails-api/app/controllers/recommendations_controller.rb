# app/controllers/recommendations_controller.rb
class RecommendationsController < ApplicationController
  before_action :authenticate_user!

  # GET /recommendations
  def index
    study_set_id = params[:study_set_id]
    recommendation_type = params[:type] || 'all'

    recommendations = if study_set_id
                        current_user.learning_recommendations
                                   .where(study_set_id: study_set_id)
                      else
                        current_user.learning_recommendations
                      end

    recommendations = recommendations.where(recommendation_type: recommendation_type) unless recommendation_type == 'all'
    recommendations = recommendations.where(status: 'pending').order(priority_level: :desc, created_at: :desc)

    render json: {
      success: true,
      recommendations: recommendations.as_json(include: [:study_set, :analysis_result]),
      count: recommendations.count
    }
  end

  # GET /recommendations/:id
  def show
    recommendation = current_user.learning_recommendations.find(params[:id])

    render json: {
      success: true,
      recommendation: recommendation.as_json(
        include: {
          study_set: { only: [:id, :title] },
          analysis_result: { only: [:id, :analysis_type, :concept_gap_score] }
        }
      )
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Recommendation not found' }, status: :not_found
  end

  # POST /recommendations/generate
  def generate
    study_set_id = params[:study_set_id]
    force_regenerate = params[:force] == 'true'

    unless study_set_id
      return render json: { error: 'study_set_id is required' }, status: :bad_request
    end

    study_set = current_user.study_sets.find(study_set_id)
    engine = RecommendationEngine.new(current_user, study_set)

    # Generate recommendations
    recommendations = engine.generate_recommendations(force: force_regenerate)

    render json: {
      success: true,
      message: 'Recommendations generated successfully',
      recommendations: recommendations.as_json,
      count: recommendations.size
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Study set not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error "Recommendation generation failed: #{e.message}"
    render json: { error: 'Failed to generate recommendations' }, status: :internal_server_error
  end

  # GET /recommendations/learning_path
  def learning_path
    study_set_id = params[:study_set_id]

    unless study_set_id
      return render json: { error: 'study_set_id is required' }, status: :bad_request
    end

    study_set = current_user.study_sets.find(study_set_id)
    engine = RecommendationEngine.new(current_user, study_set)

    learning_path = engine.generate_learning_path

    render json: {
      success: true,
      learning_path: learning_path
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Study set not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error "Learning path generation failed: #{e.message}"
    render json: { error: 'Failed to generate learning path' }, status: :internal_server_error
  end

  # POST /recommendations/:id/accept
  def accept
    recommendation = current_user.learning_recommendations.find(params[:id])

    recommendation.update!(
      status: 'in_progress',
      is_accepted: true,
      started_at: Time.current
    )

    render json: {
      success: true,
      recommendation: recommendation,
      message: 'Recommendation accepted'
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Recommendation not found' }, status: :not_found
  end

  # POST /recommendations/:id/complete
  def complete
    recommendation = current_user.learning_recommendations.find(params[:id])
    feedback_rating = params[:rating]&.to_i
    feedback_text = params[:feedback]

    recommendation.update!(
      status: 'completed',
      completed_at: Time.current,
      feedback_rating: feedback_rating,
      user_feedback: feedback_text
    )

    render json: {
      success: true,
      recommendation: recommendation,
      message: 'Recommendation completed'
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Recommendation not found' }, status: :not_found
  end

  # POST /recommendations/:id/dismiss
  def dismiss
    recommendation = current_user.learning_recommendations.find(params[:id])

    recommendation.update!(
      status: 'dismissed',
      user_feedback: params[:reason]
    )

    render json: {
      success: true,
      message: 'Recommendation dismissed'
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Recommendation not found' }, status: :not_found
  end

  # GET /recommendations/personalized
  def personalized
    study_set_id = params[:study_set_id]
    limit = (params[:limit] || 10).to_i

    unless study_set_id
      return render json: { error: 'study_set_id is required' }, status: :bad_request
    end

    study_set = current_user.study_sets.find(study_set_id)
    engine = RecommendationEngine.new(current_user, study_set)

    recommendations = engine.personalized_recommendations(limit: limit)

    render json: {
      success: true,
      recommendations: recommendations,
      explanation: engine.recommendation_explanation
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Study set not found' }, status: :not_found
  end

  # GET /recommendations/similar_users
  def similar_users
    engine = RecommendationEngine.new(current_user)
    similar_users_data = engine.find_similar_users(limit: 10)

    render json: {
      success: true,
      similar_users: similar_users_data
    }
  end

  # GET /recommendations/trending
  def trending
    study_set_id = params[:study_set_id]
    limit = (params[:limit] || 10).to_i

    trending_items = if study_set_id
                       RecommendationEngine.trending_in_study_set(study_set_id, limit: limit)
                     else
                       RecommendationEngine.global_trending(limit: limit)
                     end

    render json: {
      success: true,
      trending: trending_items
    }
  end

  # GET /recommendations/next_steps
  def next_steps
    study_set_id = params[:study_set_id]

    unless study_set_id
      return render json: { error: 'study_set_id is required' }, status: :bad_request
    end

    study_set = current_user.study_sets.find(study_set_id)
    engine = RecommendationEngine.new(current_user, study_set)

    next_steps = engine.suggest_next_steps

    render json: {
      success: true,
      next_steps: next_steps
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Study set not found' }, status: :not_found
  end

  # POST /recommendations/batch_generate
  def batch_generate
    # Queue job to generate recommendations for all study sets
    UpdateRecommendationsJob.perform_later(current_user.id)

    render json: {
      success: true,
      message: 'Batch recommendation generation started'
    }
  end

  # POST /recommendations/cf_generate - Generate collaborative filtering recommendations
  def cf_generate
    study_set = find_study_set
    service = CollaborativeFilteringService.new(current_user, study_set)
    recommendations = service.hybrid_cf_recommendations(limit: get_limit)

    render json: { success: true, algorithm: 'collaborative_filtering', recommendations: recommendations, count: recommendations.size }
  end

  # POST /recommendations/cb_generate - Generate content-based recommendations
  def cb_generate
    study_set = find_study_set
    service = ContentBasedFilteringService.new(current_user, study_set)
    recommendations = service.generate_recommendations(limit: get_limit)

    render json: { success: true, algorithm: 'content_based', recommendations: recommendations, count: recommendations.size }
  end

  # POST /recommendations/hybrid_generate - Generate hybrid recommendations
  def hybrid_generate
    study_set = find_study_set
    cf_weight = (params[:cf_weight] || 0.6).to_f
    cb_weight = (params[:cb_weight] || 0.4).to_f

    service = HybridRecommendationService.new(current_user, study_set)
    recommendations = service.generate_recommendations(limit: get_limit, cf_weight: cf_weight, cb_weight: cb_weight)

    render json: { success: true, algorithm: 'hybrid', recommendations: recommendations, count: recommendations.size, weights: { cf: cf_weight, cb: cb_weight } }
  end

  # POST /recommendations/ensemble_generate - Generate ensemble recommendations
  def ensemble_generate
    study_set = find_study_set
    service = HybridRecommendationService.new(current_user, study_set)
    recommendations = service.ensemble_recommendations(limit: get_limit)

    render json: { success: true, algorithm: 'ensemble', recommendations: recommendations, count: recommendations.size }
  end

  # POST /recommendations/adaptive_generate - Generate adaptive recommendations
  def adaptive_generate
    study_set = find_study_set
    service = HybridRecommendationService.new(current_user, study_set)
    recommendations = service.adaptive_recommendations(limit: get_limit)

    render json: { success: true, algorithm: 'adaptive', recommendations: recommendations, count: recommendations.size }
  end

  # GET /recommendations/optimal_path - Get optimal learning path
  def optimal_path
    study_set = find_study_set
    optimizer = LearningPathOptimizer.new(current_user, study_set)
    path = optimizer.generate_optimal_path

    render json: { success: true, learning_path: path }
  end

  # GET /recommendations/prioritized_concepts - Get prioritized concepts
  def prioritized_concepts
    study_set = find_study_set
    exam_date = params[:exam_date] ? Date.parse(params[:exam_date]) : nil
    optimizer = LearningPathOptimizer.new(current_user, study_set)
    concepts = optimizer.prioritize_concepts(exam_date: exam_date)

    render json: { success: true, prioritized_concepts: concepts, count: concepts.size }
  end

  # POST /recommendations/study_schedule - Generate study schedule
  def study_schedule
    study_set = find_study_set
    optimizer = LearningPathOptimizer.new(current_user, study_set)

    schedule = optimizer.generate_study_schedule(
      available_hours_per_day: (params[:available_hours_per_day] || 2).to_f,
      target_date: params[:target_date] ? Date.parse(params[:target_date]) : nil,
      preferred_session_length: (params[:preferred_session_length] || 2).to_f
    )

    render json: { success: true, study_schedule: schedule }
  end

  # GET /recommendations/next_concept - Suggest next concept to study
  def next_concept
    study_set = find_study_set
    optimizer = LearningPathOptimizer.new(current_user, study_set)
    next_concept = optimizer.suggest_next_concept

    render json: { success: true, next_concept: next_concept }
  end

  # POST /recommendations/:id/track_impression
  def track_impression
    recommendation = find_recommendation
    result = RecommendationMetricsService.new.track_impression(recommendation)
    render json: { success: true, **result }
  end

  # POST /recommendations/:id/track_click
  def track_click
    recommendation = find_recommendation
    result = RecommendationMetricsService.new.track_click(recommendation, current_user)
    render json: { success: true, **result }
  end

  # POST /recommendations/:id/track_completion
  def track_completion
    recommendation = find_recommendation
    result = RecommendationMetricsService.new.track_completion(recommendation, current_user, time_spent: params[:time_spent]&.to_i)
    render json: { success: true, **result }
  end

  # POST /recommendations/:id/track_dismissal
  def track_dismissal
    recommendation = find_recommendation
    result = RecommendationMetricsService.new.track_dismissal(recommendation, current_user, reason: params[:reason])
    render json: { success: true, **result }
  end

  # POST /recommendations/:id/rate
  def rate
    recommendation = find_recommendation
    rating = params[:rating]&.to_i
    return render json: { error: 'Rating must be between 1 and 5' }, status: :bad_request unless rating&.between?(1, 5)

    result = RecommendationMetricsService.new.track_rating(recommendation, current_user, rating, comment: params[:comment])
    render json: { success: true, **result }
  end

  # GET /recommendations/:id/metrics
  def metrics
    recommendation = find_recommendation
    service = RecommendationMetricsService.new
    summary = service.get_metrics_summary(recommendation, period: (params[:period] || 7).to_i)
    quality = service.calculate_quality_score(recommendation)

    render json: { success: true, metrics: summary, quality: quality }
  end

  # GET /recommendations/top_performing
  def top_performing
    top_recs = RecommendationMetricsService.top_performing_recommendations(
      limit: get_limit,
      period: (params[:period] || 30).to_i
    )
    render json: { success: true, top_performing: top_recs }
  end

  # GET /recommendations/algorithm_comparison
  def algorithm_comparison
    comparison = RecommendationMetricsService.algorithm_performance_comparison(period: (params[:period] || 30).to_i)
    render json: { success: true, algorithm_comparison: comparison }
  end

  # GET /recommendations/user_engagement
  def user_engagement
    engagement = RecommendationMetricsService.user_engagement_metrics(current_user, period: (params[:period] || 30).to_i)
    render json: { success: true, engagement: engagement }
  end

  # POST /recommendations/batch_generate_async
  def batch_generate_async
    return render json: { error: 'study_set_id is required' }, status: :bad_request unless params[:study_set_id]

    job = GenerateRecommendationsJob.perform_later(
      current_user.id,
      params[:study_set_id],
      { algorithm: params[:algorithm] || 'hybrid', limit: get_limit }
    )

    render json: { success: true, message: 'Recommendation generation queued', job_id: job.job_id }
  end

  # GET /recommendations/similarity_scores
  def similarity_scores
    similar_users = UserSimilarityScore.find_similar_users(
      current_user,
      limit: get_limit,
      min_similarity: (params[:min_similarity] || 60.0).to_f
    )

    render json: {
      success: true,
      similar_users: similar_users.map { |s| { user_id: s.similar_user_id, similarity_score: s.similarity_score, similarity_type: s.similarity_type, common_concepts: s.common_concepts_count, calculated_at: s.calculated_at } }
    }
  end

  # POST /recommendations/calculate_similarities
  def calculate_similarities
    UserSimilarityScore.batch_calculate_for_user(current_user, type: params[:type] || 'cosine', limit: (params[:limit] || 50).to_i)
    render json: { success: true, message: 'Similarity calculation completed', type: params[:type] || 'cosine' }
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :internal_server_error
  end

  # GET /recommendations/daily_report
  def daily_report
    date = params[:date] ? Date.parse(params[:date]) : Date.current
    report = RecommendationMetricsService.generate_daily_report(date)
    render json: { success: true, report: report }
  end

  private

  def recommendation_params
    params.permit(:study_set_id, :type, :force, :limit, :rating, :feedback, :reason)
  end

  def find_study_set
    return render json: { error: 'study_set_id is required' }, status: :bad_request unless params[:study_set_id]
    current_user.study_sets.find(params[:study_set_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Study set not found' }, status: :not_found
  end

  def find_recommendation
    current_user.learning_recommendations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Recommendation not found' }, status: :not_found
  end

  def get_limit
    (params[:limit] || 10).to_i
  end
end
