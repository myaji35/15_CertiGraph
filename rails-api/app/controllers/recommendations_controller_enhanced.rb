# app/controllers/recommendations_controller_enhanced.rb
# This file contains additional endpoints to be merged into recommendations_controller.rb

# Add these methods to RecommendationsController class:

# POST /recommendations/cf_generate - Generate collaborative filtering recommendations
def cf_generate
  study_set_id = params[:study_set_id]
  limit = (params[:limit] || 10).to_i

  unless study_set_id
    return render json: { error: 'study_set_id is required' }, status: :bad_request
  end

  study_set = current_user.study_sets.find(study_set_id)
  service = CollaborativeFilteringService.new(current_user, study_set)

  recommendations = service.hybrid_cf_recommendations(limit: limit)

  render json: {
    success: true,
    algorithm: 'collaborative_filtering',
    recommendations: recommendations,
    count: recommendations.size
  }
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Study set not found' }, status: :not_found
end

# POST /recommendations/cb_generate - Generate content-based recommendations
def cb_generate
  study_set_id = params[:study_set_id]
  limit = (params[:limit] || 10).to_i

  unless study_set_id
    return render json: { error: 'study_set_id is required' }, status: :bad_request
  end

  study_set = current_user.study_sets.find(study_set_id)
  service = ContentBasedFilteringService.new(current_user, study_set)

  recommendations = service.generate_recommendations(limit: limit)

  render json: {
    success: true,
    algorithm: 'content_based',
    recommendations: recommendations,
    count: recommendations.size
  }
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Study set not found' }, status: :not_found
end

# POST /recommendations/hybrid_generate - Generate hybrid recommendations
def hybrid_generate
  study_set_id = params[:study_set_id]
  limit = (params[:limit] || 10).to_i
  cf_weight = (params[:cf_weight] || 0.6).to_f
  cb_weight = (params[:cb_weight] || 0.4).to_f

  unless study_set_id
    return render json: { error: 'study_set_id is required' }, status: :bad_request
  end

  study_set = current_user.study_sets.find(study_set_id)
  service = HybridRecommendationService.new(current_user, study_set)

  recommendations = service.generate_recommendations(
    limit: limit,
    cf_weight: cf_weight,
    cb_weight: cb_weight
  )

  render json: {
    success: true,
    algorithm: 'hybrid',
    recommendations: recommendations,
    count: recommendations.size,
    weights: { cf: cf_weight, cb: cb_weight }
  }
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Study set not found' }, status: :not_found
end

# POST /recommendations/ensemble_generate - Generate ensemble recommendations
def ensemble_generate
  study_set_id = params[:study_set_id]
  limit = (params[:limit] || 10).to_i

  unless study_set_id
    return render json: { error: 'study_set_id is required' }, status: :bad_request
  end

  study_set = current_user.study_sets.find(study_set_id)
  service = HybridRecommendationService.new(current_user, study_set)

  recommendations = service.ensemble_recommendations(limit: limit)

  render json: {
    success: true,
    algorithm: 'ensemble',
    recommendations: recommendations,
    count: recommendations.size
  }
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Study set not found' }, status: :not_found
end

# POST /recommendations/adaptive_generate - Generate adaptive recommendations
def adaptive_generate
  study_set_id = params[:study_set_id]
  limit = (params[:limit] || 10).to_i

  unless study_set_id
    return render json: { error: 'study_set_id is required' }, status: :bad_request
  end

  study_set = current_user.study_sets.find(study_set_id)
  service = HybridRecommendationService.new(current_user, study_set)

  recommendations = service.adaptive_recommendations(limit: limit)

  render json: {
    success: true,
    algorithm: 'adaptive',
    recommendations: recommendations,
    count: recommendations.size
  }
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Study set not found' }, status: :not_found
end

# GET /recommendations/optimal_path - Get optimal learning path
def optimal_path
  study_set_id = params[:study_set_id]

  unless study_set_id
    return render json: { error: 'study_set_id is required' }, status: :bad_request
  end

  study_set = current_user.study_sets.find(study_set_id)
  optimizer = LearningPathOptimizer.new(current_user, study_set)

  path = optimizer.generate_optimal_path

  render json: {
    success: true,
    learning_path: path
  }
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Study set not found' }, status: :not_found
end

# GET /recommendations/prioritized_concepts - Get prioritized concepts
def prioritized_concepts
  study_set_id = params[:study_set_id]
  exam_date = params[:exam_date]

  unless study_set_id
    return render json: { error: 'study_set_id is required' }, status: :bad_request
  end

  study_set = current_user.study_sets.find(study_set_id)
  optimizer = LearningPathOptimizer.new(current_user, study_set)

  exam_date = Date.parse(exam_date) if exam_date
  concepts = optimizer.prioritize_concepts(exam_date: exam_date)

  render json: {
    success: true,
    prioritized_concepts: concepts,
    count: concepts.size
  }
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Study set not found' }, status: :not_found
end

# POST /recommendations/study_schedule - Generate study schedule
def study_schedule
  study_set_id = params[:study_set_id]
  available_hours_per_day = (params[:available_hours_per_day] || 2).to_f
  target_date = params[:target_date]
  preferred_session_length = (params[:preferred_session_length] || 2).to_f

  unless study_set_id
    return render json: { error: 'study_set_id is required' }, status: :bad_request
  end

  study_set = current_user.study_sets.find(study_set_id)
  optimizer = LearningPathOptimizer.new(current_user, study_set)

  target_date = Date.parse(target_date) if target_date
  schedule = optimizer.generate_study_schedule(
    available_hours_per_day: available_hours_per_day,
    target_date: target_date,
    preferred_session_length: preferred_session_length
  )

  render json: {
    success: true,
    study_schedule: schedule
  }
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Study set not found' }, status: :not_found
end

# GET /recommendations/next_concept - Suggest next concept to study
def next_concept
  study_set_id = params[:study_set_id]

  unless study_set_id
    return render json: { error: 'study_set_id is required' }, status: :bad_request
  end

  study_set = current_user.study_sets.find(study_set_id)
  optimizer = LearningPathOptimizer.new(current_user, study_set)

  next_concept = optimizer.suggest_next_concept

  if next_concept
    render json: {
      success: true,
      next_concept: next_concept
    }
  else
    render json: {
      success: true,
      message: 'No concepts available to study',
      next_concept: nil
    }
  end
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Study set not found' }, status: :not_found
end

# POST /recommendations/:id/track_impression - Track impression
def track_impression
  recommendation = current_user.learning_recommendations.find(params[:id])
  metrics_service = RecommendationMetricsService.new

  result = metrics_service.track_impression(recommendation)

  render json: {
    success: true,
    **result
  }
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Recommendation not found' }, status: :not_found
end

# POST /recommendations/:id/track_click - Track click
def track_click
  recommendation = current_user.learning_recommendations.find(params[:id])
  metrics_service = RecommendationMetricsService.new

  result = metrics_service.track_click(recommendation, current_user)

  render json: {
    success: true,
    **result
  }
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Recommendation not found' }, status: :not_found
end

# POST /recommendations/:id/track_completion - Track completion
def track_completion
  recommendation = current_user.learning_recommendations.find(params[:id])
  time_spent = params[:time_spent]&.to_i

  metrics_service = RecommendationMetricsService.new
  result = metrics_service.track_completion(recommendation, current_user, time_spent: time_spent)

  render json: {
    success: true,
    **result
  }
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Recommendation not found' }, status: :not_found
end

# POST /recommendations/:id/track_dismissal - Track dismissal
def track_dismissal
  recommendation = current_user.learning_recommendations.find(params[:id])
  reason = params[:reason]

  metrics_service = RecommendationMetricsService.new
  result = metrics_service.track_dismissal(recommendation, current_user, reason: reason)

  render json: {
    success: true,
    **result
  }
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Recommendation not found' }, status: :not_found
end

# POST /recommendations/:id/rate - Rate recommendation
def rate
  recommendation = current_user.learning_recommendations.find(params[:id])
  rating = params[:rating]&.to_i
  comment = params[:comment]

  unless rating && rating.between?(1, 5)
    return render json: { error: 'Rating must be between 1 and 5' }, status: :bad_request
  end

  metrics_service = RecommendationMetricsService.new
  result = metrics_service.track_rating(recommendation, current_user, rating, comment: comment)

  render json: {
    success: true,
    **result
  }
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Recommendation not found' }, status: :not_found
end

# GET /recommendations/:id/metrics - Get metrics for a recommendation
def metrics
  recommendation = current_user.learning_recommendations.find(params[:id])
  period = (params[:period] || 7).to_i

  metrics_service = RecommendationMetricsService.new
  summary = metrics_service.get_metrics_summary(recommendation, period: period)
  quality = metrics_service.calculate_quality_score(recommendation)

  render json: {
    success: true,
    metrics: summary,
    quality: quality
  }
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Recommendation not found' }, status: :not_found
end

# GET /recommendations/top_performing - Get top performing recommendations
def top_performing
  limit = (params[:limit] || 10).to_i
  period = (params[:period] || 30).to_i

  top_recs = RecommendationMetricsService.top_performing_recommendations(
    limit: limit,
    period: period
  )

  render json: {
    success: true,
    top_performing: top_recs
  }
end

# GET /recommendations/algorithm_comparison - Compare algorithm performance
def algorithm_comparison
  period = (params[:period] || 30).to_i

  comparison = RecommendationMetricsService.algorithm_performance_comparison(period: period)

  render json: {
    success: true,
    algorithm_comparison: comparison
  }
end

# GET /recommendations/user_engagement - Get user engagement metrics
def user_engagement
  period = (params[:period] || 30).to_i

  engagement = RecommendationMetricsService.user_engagement_metrics(current_user, period: period)

  render json: {
    success: true,
    engagement: engagement
  }
end

# POST /recommendations/batch_generate_async - Generate recommendations asynchronously
def batch_generate_async
  study_set_id = params[:study_set_id]
  algorithm = params[:algorithm] || 'hybrid'
  limit = (params[:limit] || 10).to_i

  unless study_set_id
    return render json: { error: 'study_set_id is required' }, status: :bad_request
  end

  # Queue the job
  job = GenerateRecommendationsJob.perform_later(
    current_user.id,
    study_set_id,
    { algorithm: algorithm, limit: limit }
  )

  render json: {
    success: true,
    message: 'Recommendation generation queued',
    job_id: job.job_id,
    algorithm: algorithm,
    limit: limit
  }
end

# GET /recommendations/similarity_scores - Get user similarity scores
def similarity_scores
  limit = (params[:limit] || 10).to_i
  min_similarity = (params[:min_similarity] || 60.0).to_f

  similar_users = UserSimilarityScore.find_similar_users(
    current_user,
    limit: limit,
    min_similarity: min_similarity
  )

  render json: {
    success: true,
    similar_users: similar_users.map do |score|
      {
        user_id: score.similar_user_id,
        similarity_score: score.similarity_score,
        similarity_type: score.similarity_type,
        common_concepts: score.common_concepts_count,
        calculated_at: score.calculated_at
      }
    end
  }
end

# POST /recommendations/calculate_similarities - Calculate user similarities
def calculate_similarities
  similarity_type = params[:type] || 'cosine'
  limit = (params[:limit] || 50).to_i

  # Queue calculation in background
  UserSimilarityScore.batch_calculate_for_user(
    current_user,
    type: similarity_type,
    limit: limit
  )

  render json: {
    success: true,
    message: 'Similarity calculation completed',
    type: similarity_type
  }
rescue StandardError => e
  render json: {
    success: false,
    error: e.message
  }, status: :internal_server_error
end

# GET /recommendations/daily_report - Get daily metrics report
def daily_report
  date = params[:date] ? Date.parse(params[:date]) : Date.current

  report = RecommendationMetricsService.generate_daily_report(date)

  render json: {
    success: true,
    report: report
  }
end
