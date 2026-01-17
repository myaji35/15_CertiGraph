# app/services/hybrid_recommendation_service.rb
class HybridRecommendationService
  attr_reader :user, :study_set, :cf_service, :cb_service

  DEFAULT_CF_WEIGHT = 0.6
  DEFAULT_CB_WEIGHT = 0.4

  def initialize(user, study_set = nil)
    @user = user
    @study_set = study_set
    @cf_service = CollaborativeFilteringService.new(user, study_set)
    @cb_service = ContentBasedFilteringService.new(user, study_set)
  end

  # Generate hybrid recommendations combining CF and CB
  def generate_recommendations(limit: 10, cf_weight: DEFAULT_CF_WEIGHT, cb_weight: DEFAULT_CB_WEIGHT)
    # Validate weights
    total_weight = cf_weight + cb_weight
    cf_weight = cf_weight / total_weight
    cb_weight = cb_weight / total_weight

    # Get recommendations from both engines
    cf_recs = get_cf_recommendations(limit: limit * 2)
    cb_recs = get_cb_recommendations(limit: limit * 2)

    # Combine and reweight
    combined = combine_recommendations(cf_recs, cb_recs, cf_weight, cb_weight)

    # Apply diversity and novelty filters
    filtered = apply_filters(combined, limit: limit)

    # Format final recommendations
    filtered.take(limit).map do |rec|
      {
        question_id: rec[:question_id],
        score: rec[:hybrid_score],
        reason: rec[:reason],
        algorithm: 'hybrid',
        confidence: rec[:confidence],
        metadata: {
          cf_score: rec[:cf_score],
          cb_score: rec[:cb_score],
          cf_weight: cf_weight,
          cb_weight: cb_weight,
          diversity_score: rec[:diversity_score],
          sources: rec[:sources]
        }
      }
    end
  end

  # Adaptive hybrid: Adjust weights based on user behavior
  def adaptive_recommendations(limit: 10)
    # Calculate optimal weights based on user's historical preferences
    weights = calculate_adaptive_weights

    generate_recommendations(
      limit: limit,
      cf_weight: weights[:cf_weight],
      cb_weight: weights[:cb_weight]
    )
  end

  # Context-aware recommendations
  def context_aware_recommendations(context: {}, limit: 10)
    # Adjust strategy based on context
    cf_weight, cb_weight = determine_contextual_weights(context)

    recommendations = generate_recommendations(
      limit: limit * 2,
      cf_weight: cf_weight,
      cb_weight: cb_weight
    )

    # Apply context-specific filtering
    apply_contextual_filters(recommendations, context).take(limit)
  end

  # Ensemble recommendations (multiple strategies)
  def ensemble_recommendations(limit: 10)
    strategies = [
      { method: :user_based_cf, weight: 0.3 },
      { method: :item_based_cf, weight: 0.2 },
      { method: :content_based, weight: 0.25 },
      { method: :weakness_based, weight: 0.25 }
    ]

    all_recommendations = {}

    strategies.each do |strategy|
      recs = get_recommendations_by_strategy(strategy[:method], limit: limit * 2)

      recs.each do |rec|
        qid = rec[:question_id]
        if all_recommendations[qid]
          all_recommendations[qid][:score] += rec[:score] * strategy[:weight]
          all_recommendations[qid][:sources] << strategy[:method]
        else
          all_recommendations[qid] = {
            question_id: qid,
            score: rec[:score] * strategy[:weight],
            sources: [strategy[:method]],
            metadata: rec[:metadata] || {}
          }
        end
      end
    end

    # Sort by combined score
    sorted = all_recommendations.values.sort_by { |r| -r[:score] }

    sorted.take(limit).map do |rec|
      {
        question_id: rec[:question_id],
        score: rec[:score],
        reason: "다중 추천 알고리즘 조합 (#{rec[:sources].join(', ')})",
        algorithm: 'ensemble',
        confidence: calculate_ensemble_confidence(rec[:sources]),
        metadata: rec[:metadata].merge(sources: rec[:sources])
      }
    end
  end

  private

  # Get CF recommendations
  def get_cf_recommendations(limit: 20)
    begin
      cf_service.hybrid_cf_recommendations(limit: limit)
    rescue StandardError => e
      Rails.logger.error "CF recommendations failed: #{e.message}"
      []
    end
  end

  # Get CB recommendations
  def get_cb_recommendations(limit: 20)
    begin
      cb_service.generate_recommendations(limit: limit)
    rescue StandardError => e
      Rails.logger.error "CB recommendations failed: #{e.message}"
      []
    end
  end

  # Combine CF and CB recommendations
  def combine_recommendations(cf_recs, cb_recs, cf_weight, cb_weight)
    combined = {}

    # Add CF recommendations
    cf_recs.each do |rec|
      qid = rec[:question_id]
      combined[qid] = {
        question_id: qid,
        cf_score: rec[:score],
        cb_score: 0.0,
        hybrid_score: rec[:score] * cf_weight,
        sources: ['collaborative_filtering'],
        cf_metadata: rec[:metadata],
        cb_metadata: {}
      }
    end

    # Add CB recommendations
    cb_recs.each do |rec|
      qid = rec[:question_id]
      if combined[qid]
        combined[qid][:cb_score] = rec[:score]
        combined[qid][:hybrid_score] += rec[:score] * cb_weight
        combined[qid][:sources] << 'content_based'
        combined[qid][:cb_metadata] = rec[:metadata]
      else
        combined[qid] = {
          question_id: qid,
          cf_score: 0.0,
          cb_score: rec[:score],
          hybrid_score: rec[:score] * cb_weight,
          sources: ['content_based'],
          cf_metadata: {},
          cb_metadata: rec[:metadata]
        }
      end
    end

    # Calculate combined metrics
    combined.values.each do |rec|
      rec[:confidence] = calculate_hybrid_confidence(rec)
      rec[:reason] = generate_hybrid_reason(rec)
      rec[:diversity_score] = calculate_diversity_score(rec)
    end

    combined.values
  end

  # Apply filters for diversity and quality
  def apply_filters(recommendations, limit: 10)
    # Sort by score
    sorted = recommendations.sort_by { |r| -r[:hybrid_score] }

    # Apply diversity filter
    diversified = apply_diversity_filter(sorted, limit: limit * 1.5)

    # Apply novelty boost
    diversified.each do |rec|
      if rec[:sources].size > 1
        rec[:hybrid_score] *= 1.1 # Boost items recommended by both engines
      end
    end

    # Re-sort after boosting
    diversified.sort_by { |r| -r[:hybrid_score] }
  end

  # Apply diversity filter to avoid repetitive content
  def apply_diversity_filter(recommendations, limit: 15)
    return recommendations if recommendations.size <= limit

    selected = []
    used_concepts = Set.new

    recommendations.each do |rec|
      # Get concepts for this question
      concepts = get_question_concepts(rec[:question_id])

      # Check for concept overlap
      overlap = (concepts & used_concepts).size
      total_concepts = concepts.size

      diversity_ratio = total_concepts > 0 ? (1.0 - overlap.to_f / total_concepts) : 1.0

      # Select if diverse enough or we need more items
      if diversity_ratio > 0.3 || selected.size < limit * 0.5
        selected << rec
        used_concepts.merge(concepts)
      end

      break if selected.size >= limit
    end

    selected
  end

  # Get concepts for a question
  def get_question_concepts(question_id)
    QuestionConcept.where(question_id: question_id)
                  .pluck(:knowledge_node_id)
  end

  # Calculate hybrid confidence
  def calculate_hybrid_confidence(recommendation)
    cf_score = recommendation[:cf_score]
    cb_score = recommendation[:cb_score]

    # Higher confidence when both engines agree
    if cf_score > 0 && cb_score > 0
      base_confidence = 0.9
      score_variance = (cf_score - cb_score).abs
      base_confidence - (score_variance * 0.01)
    elsif cf_score > 0 || cb_score > 0
      0.7
    else
      0.5
    end
  end

  # Generate hybrid reason
  def generate_hybrid_reason(recommendation)
    sources = recommendation[:sources]

    if sources.include?('collaborative_filtering') && sources.include?('content_based')
      "유사 학습자와 학습 내용 분석 기반 추천"
    elsif sources.include?('collaborative_filtering')
      "유사 학습자 기반 추천"
    elsif sources.include?('content_based')
      "학습 내용 분석 기반 추천"
    else
      "종합 분석 추천"
    end
  end

  # Calculate diversity score
  def calculate_diversity_score(recommendation)
    # Higher diversity when recommended by multiple sources
    base_score = recommendation[:sources].size * 0.3

    # Add variety from CB metadata
    if recommendation[:cb_metadata][:novelty_score]
      base_score += recommendation[:cb_metadata][:novelty_score] * 0.3
    end

    [base_score, 1.0].min.round(2)
  end

  # Calculate adaptive weights based on user behavior
  def calculate_adaptive_weights
    # Get user's feedback history
    feedbacks = RecommendationFeedback.joins(:learning_recommendation)
                                     .where(user: user)
                                     .where('recommendation_feedbacks.created_at >= ?', 30.days.ago)

    return { cf_weight: DEFAULT_CF_WEIGHT, cb_weight: DEFAULT_CB_WEIGHT } if feedbacks.empty?

    # Calculate success rate for each algorithm
    cf_feedbacks = feedbacks.where(learning_recommendations: { recommendation_algorithm: 'collaborative_filtering' })
    cb_feedbacks = feedbacks.where(learning_recommendations: { recommendation_algorithm: 'content_based' })

    cf_success_rate = calculate_success_rate(cf_feedbacks)
    cb_success_rate = calculate_success_rate(cb_feedbacks)

    # Adjust weights based on success rates
    total_rate = cf_success_rate + cb_success_rate
    return { cf_weight: DEFAULT_CF_WEIGHT, cb_weight: DEFAULT_CB_WEIGHT } if total_rate.zero?

    {
      cf_weight: (cf_success_rate / total_rate * 0.8 + 0.2).round(2), # Smooth adjustment
      cb_weight: (cb_success_rate / total_rate * 0.8 + 0.2).round(2)
    }
  end

  # Calculate success rate from feedbacks
  def calculate_success_rate(feedbacks)
    return 0.0 if feedbacks.empty?

    successful = feedbacks.where(was_helpful: true).count
    (successful.to_f / feedbacks.count * 100).round(2)
  end

  # Determine weights based on context
  def determine_contextual_weights(context)
    # Default weights
    cf_weight = DEFAULT_CF_WEIGHT
    cb_weight = DEFAULT_CB_WEIGHT

    # Adjust based on context
    case context[:focus]
    when 'exploration'
      # More collaborative for exploration
      cf_weight = 0.7
      cb_weight = 0.3
    when 'weakness'
      # More content-based for targeted learning
      cf_weight = 0.3
      cb_weight = 0.7
    when 'review'
      # Balanced
      cf_weight = 0.5
      cb_weight = 0.5
    end

    # Adjust for user experience level
    if context[:user_level] == 'beginner'
      cb_weight += 0.1 # Beginners benefit more from structured content
      cf_weight -= 0.1
    elsif context[:user_level] == 'advanced'
      cf_weight += 0.1 # Advanced users benefit from collaborative discovery
      cb_weight -= 0.1
    end

    [cf_weight, cb_weight]
  end

  # Apply context-specific filters
  def apply_contextual_filters(recommendations, context)
    filtered = recommendations

    # Filter by difficulty if specified
    if context[:difficulty]
      filtered = filter_by_difficulty(filtered, context[:difficulty])
    end

    # Filter by time constraint
    if context[:time_limit]
      filtered = filter_by_time(filtered, context[:time_limit])
    end

    # Filter by topic focus
    if context[:topic]
      filtered = filter_by_topic(filtered, context[:topic])
    end

    filtered
  end

  # Get recommendations by specific strategy
  def get_recommendations_by_strategy(strategy, limit: 20)
    case strategy
    when :user_based_cf
      cf_service.user_based_recommendations(limit: limit)
    when :item_based_cf
      cf_service.item_based_recommendations(limit: limit)
    when :content_based
      cb_service.generate_recommendations(limit: limit)
    when :weakness_based
      cb_service.weakness_based_recommendations(limit: limit)
    else
      []
    end
  rescue StandardError => e
    Rails.logger.error "Strategy #{strategy} failed: #{e.message}"
    []
  end

  # Calculate ensemble confidence
  def calculate_ensemble_confidence(sources)
    # More sources = higher confidence
    case sources.size
    when 4 then 0.95
    when 3 then 0.85
    when 2 then 0.75
    else 0.65
    end
  end

  # Filter helpers
  def filter_by_difficulty(recommendations, difficulty)
    # Implementation depends on question difficulty data
    recommendations
  end

  def filter_by_time(recommendations, time_limit)
    # Implementation depends on estimated completion time
    recommendations.take(time_limit / 5) # Assume 5 min per question
  end

  def filter_by_topic(recommendations, topic)
    # Implementation depends on question topic data
    recommendations
  end
end
