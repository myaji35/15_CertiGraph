# app/services/recommendation_metrics_service.rb
class RecommendationMetricsService
  attr_reader :recommendation

  def initialize(recommendation = nil)
    @recommendation = recommendation
  end

  # Track impression (recommendation shown to user)
  def track_impression(recommendation)
    metric = RecommendationMetric.for_today(recommendation)
    metric.record_impression!

    # Also update recommendation model
    recommendation.increment!(:impressions_count)

    {
      success: true,
      impressions: metric.impressions,
      ctr: metric.ctr
    }
  end

  # Track click (user clicked on recommendation)
  def track_click(recommendation, user)
    metric = RecommendationMetric.for_today(recommendation)
    metric.record_click!

    # Update recommendation model
    recommendation.increment!(:clicks_count)

    # Record feedback
    RecommendationFeedback.track_interaction(
      user: user,
      recommendation: recommendation,
      type: 'clicked'
    )

    {
      success: true,
      clicks: metric.clicks,
      ctr: metric.ctr
    }
  end

  # Track completion
  def track_completion(recommendation, user, time_spent: nil)
    metric = RecommendationMetric.for_today(recommendation)
    metric.record_completion!

    # Record feedback with time
    RecommendationFeedback.track_interaction(
      user: user,
      recommendation: recommendation,
      type: 'completed',
      metadata: { time_spent_seconds: time_spent }
    )

    {
      success: true,
      completions: metric.completions,
      completion_rate: metric.completion_rate
    }
  end

  # Track dismissal
  def track_dismissal(recommendation, user, reason: nil)
    metric = RecommendationMetric.for_today(recommendation)
    metric.record_dismissal!

    # Record feedback with reason
    RecommendationFeedback.create!(
      user: user,
      learning_recommendation: recommendation,
      feedback_type: 'dismissed',
      comment: reason,
      was_helpful: false
    )

    {
      success: true,
      dismissals: metric.dismissals
    }
  end

  # Track rating
  def track_rating(recommendation, user, rating, comment: nil)
    # Record feedback
    feedback = RecommendationFeedback.create!(
      user: user,
      learning_recommendation: recommendation,
      feedback_type: 'rated',
      rating: rating,
      comment: comment,
      was_helpful: rating >= 4
    )

    # Update metric
    update_average_rating(recommendation)

    {
      success: true,
      rating: rating,
      feedback_id: feedback.id
    }
  end

  # Get metrics summary for a recommendation
  def get_metrics_summary(recommendation, period: 7)
    start_date = period.days.ago.to_date
    end_date = Date.current

    aggregate = RecommendationMetric.aggregate_metrics(
      recommendation,
      start_date,
      end_date
    )

    feedbacks = RecommendationFeedback.summary_for(recommendation)

    {
      period_days: period,
      impressions: aggregate[:total_impressions],
      clicks: aggregate[:total_clicks],
      completions: aggregate[:total_completions],
      dismissals: aggregate[:total_dismissals],
      ctr: aggregate[:avg_ctr],
      completion_rate: aggregate[:avg_completion_rate],
      avg_rating: feedbacks[:avg_rating],
      total_ratings: feedbacks[:ratings],
      helpful_count: feedbacks[:helpful_count],
      not_helpful_count: feedbacks[:not_helpful_count]
    }
  end

  # Calculate recommendation quality score
  def calculate_quality_score(recommendation)
    metrics = get_metrics_summary(recommendation, period: 30)

    # Quality factors
    ctr_score = normalize_score(metrics[:ctr], max: 50.0) * 0.3
    completion_score = normalize_score(metrics[:completion_rate], max: 80.0) * 0.3
    rating_score = normalize_score(metrics[:avg_rating] * 20, max: 100.0) * 0.4

    quality_score = (ctr_score + completion_score + rating_score).round(2)

    {
      quality_score: quality_score,
      ctr_contribution: ctr_score,
      completion_contribution: completion_score,
      rating_contribution: rating_score,
      grade: grade_quality(quality_score)
    }
  end

  # Get top performing recommendations
  def self.top_performing_recommendations(limit: 10, period: 30)
    start_date = period.days.ago.to_date

    metrics = RecommendationMetric.where('metric_date >= ?', start_date)
                                 .group(:learning_recommendation_id)
                                 .select(
                                   'learning_recommendation_id',
                                   'AVG(ctr) as avg_ctr',
                                   'AVG(completion_rate) as avg_completion_rate',
                                   'SUM(impressions) as total_impressions',
                                   'SUM(clicks) as total_clicks'
                                 )
                                 .having('SUM(impressions) >= ?', 10) # Min impressions threshold
                                 .order('avg_ctr DESC, avg_completion_rate DESC')
                                 .limit(limit)

    metrics.map do |m|
      recommendation = LearningRecommendation.find(m.learning_recommendation_id)

      {
        recommendation_id: m.learning_recommendation_id,
        recommendation_type: recommendation.recommendation_type,
        avg_ctr: m.avg_ctr.round(2),
        avg_completion_rate: m.avg_completion_rate.round(2),
        total_impressions: m.total_impressions,
        total_clicks: m.total_clicks
      }
    end
  end

  # Get algorithm performance comparison
  def self.algorithm_performance_comparison(period: 30)
    start_date = period.days.ago.to_date

    algorithms = %w[collaborative_filtering content_based hybrid ensemble]

    comparison = algorithms.map do |algorithm|
      recommendations = LearningRecommendation.where(recommendation_algorithm: algorithm)

      next nil if recommendations.empty?

      rec_ids = recommendations.pluck(:id)
      metrics = RecommendationMetric.where(learning_recommendation_id: rec_ids)
                                   .where('metric_date >= ?', start_date)

      feedbacks = RecommendationFeedback.joins(:learning_recommendation)
                                       .where(learning_recommendations: { recommendation_algorithm: algorithm })
                                       .where('recommendation_feedbacks.created_at >= ?', start_date.to_time)

      {
        algorithm: algorithm,
        total_recommendations: recommendations.count,
        avg_ctr: metrics.average(:ctr)&.round(2) || 0.0,
        avg_completion_rate: metrics.average(:completion_rate)&.round(2) || 0.0,
        avg_rating: feedbacks.average(:rating)&.round(2) || 0.0,
        total_impressions: metrics.sum(:impressions),
        total_clicks: metrics.sum(:clicks),
        total_completions: metrics.sum(:completions)
      }
    end.compact

    comparison.sort_by { |c| -c[:avg_ctr] }
  end

  # Get user engagement metrics
  def self.user_engagement_metrics(user, period: 30)
    start_date = period.days.ago

    recommendations = user.learning_recommendations
                         .where('created_at >= ?', start_date)

    feedbacks = RecommendationFeedback.where(user: user)
                                     .where('created_at >= ?', start_date)

    {
      total_recommendations_received: recommendations.count,
      recommendations_clicked: feedbacks.clicked.count,
      recommendations_completed: feedbacks.completed.count,
      recommendations_dismissed: feedbacks.dismissed.count,
      avg_rating_given: feedbacks.rated.average(:rating)&.round(2) || 0.0,
      engagement_rate: calculate_engagement_rate(recommendations.count, feedbacks.count),
      active_days: feedbacks.pluck(:created_at).map(&:to_date).uniq.count
    }
  end

  # Predict recommendation success
  def predict_success(recommendation)
    # Get similar historical recommendations
    similar_recs = find_similar_recommendations(recommendation, limit: 20)

    return { predicted_ctr: 0.0, predicted_completion_rate: 0.0, confidence: 'low' } if similar_recs.empty?

    # Calculate average performance
    similar_rec_ids = similar_recs.map(&:id)
    metrics = RecommendationMetric.where(learning_recommendation_id: similar_rec_ids)

    predicted_ctr = metrics.average(:ctr)&.round(2) || 0.0
    predicted_completion_rate = metrics.average(:completion_rate)&.round(2) || 0.0

    confidence = similar_recs.size >= 10 ? 'high' : 'medium'

    {
      predicted_ctr: predicted_ctr,
      predicted_completion_rate: predicted_completion_rate,
      confidence: confidence,
      based_on_samples: similar_recs.size
    }
  end

  # Generate daily metrics report
  def self.generate_daily_report(date = Date.current)
    metrics = RecommendationMetric.for_date(date)

    {
      date: date,
      total_impressions: metrics.sum(:impressions),
      total_clicks: metrics.sum(:clicks),
      total_completions: metrics.sum(:completions),
      total_dismissals: metrics.sum(:dismissals),
      avg_ctr: metrics.average(:ctr)&.round(2) || 0.0,
      avg_completion_rate: metrics.average(:completion_rate)&.round(2) || 0.0,
      recommendations_tracked: metrics.count,
      top_performing: metrics.order(ctr: :desc).limit(5).pluck(:learning_recommendation_id)
    }
  end

  private

  # Update average rating for a recommendation
  def update_average_rating(recommendation)
    avg_rating = RecommendationFeedback.where(learning_recommendation: recommendation)
                                      .where(feedback_type: 'rated')
                                      .average(:rating)

    metrics = RecommendationMetric.where(learning_recommendation: recommendation)
    metrics.update_all(avg_rating: avg_rating)
  end

  # Normalize score to 0-100 range
  def normalize_score(value, max:)
    return 0.0 if max.zero?
    [(value.to_f / max * 100), 100.0].min
  end

  # Grade quality score
  def grade_quality(score)
    case score
    when 80..100 then 'A'
    when 60...80 then 'B'
    when 40...60 then 'C'
    when 20...40 then 'D'
    else 'F'
    end
  end

  # Calculate engagement rate
  def self.calculate_engagement_rate(total_recommendations, total_interactions)
    return 0.0 if total_recommendations.zero?
    (total_interactions.to_f / total_recommendations * 100).round(2)
  end

  # Find similar recommendations for prediction
  def find_similar_recommendations(recommendation, limit: 20)
    LearningRecommendation.where(
      recommendation_type: recommendation.recommendation_type,
      recommendation_algorithm: recommendation.recommendation_algorithm
    )
    .where.not(id: recommendation.id)
    .where('created_at >= ?', 90.days.ago)
    .limit(limit)
  end
end
