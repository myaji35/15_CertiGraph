# Service for predicting future performance and outcomes
class PerformancePredictorService
  attr_reader :user, :study_set, :historical_data

  def initialize(user, study_set: nil)
    @user = user
    @study_set = study_set
    @historical_data = load_historical_data
  end

  # Main prediction method
  def predict_performance
    {
      exam_score_prediction: predict_exam_score,
      mastery_timeline: predict_mastery_timeline,
      completion_prediction: predict_completion,
      goal_achievement: predict_goal_achievement,
      risk_assessment: assess_risks,
      improvement_trajectory: calculate_improvement_trajectory,
      recommendations: generate_recommendations
    }
  end

  # Predict expected exam score based on current performance
  def predict_exam_score
    current_mastery = calculate_current_mastery
    current_accuracy = calculate_current_accuracy
    coverage = calculate_coverage

    # Weighted prediction model
    # 50% mastery, 30% accuracy, 20% coverage
    base_score = (current_mastery * 50) + (current_accuracy * 0.3) + (coverage * 20)

    # Adjust for trend
    trend_adjustment = calculate_trend_adjustment
    predicted_score = base_score + trend_adjustment

    # Apply confidence interval
    confidence = calculate_prediction_confidence

    {
      predicted_score: predicted_score.round(2),
      confidence_level: confidence,
      confidence_interval: {
        lower: (predicted_score - (10 * (1 - confidence))).round(2),
        upper: (predicted_score + (10 * (1 - confidence))).round(2)
      },
      factors: {
        mastery_contribution: (current_mastery * 50).round(2),
        accuracy_contribution: (current_accuracy * 0.3).round(2),
        coverage_contribution: (coverage * 20).round(2),
        trend_adjustment: trend_adjustment.round(2)
      },
      grade_prediction: score_to_grade(predicted_score),
      pass_probability: calculate_pass_probability(predicted_score)
    }
  end

  # Predict timeline to achieve target mastery
  def predict_mastery_timeline(target_mastery: 0.8)
    current_mastery = calculate_current_mastery
    return { already_achieved: true } if current_mastery >= target_mastery

    learning_rate = calculate_learning_rate
    remaining_mastery = target_mastery - current_mastery

    # Calculate based on current learning rate
    if learning_rate > 0
      estimated_days = (remaining_mastery / learning_rate).ceil
      estimated_hours = calculate_required_hours(remaining_mastery)

      {
        current_mastery: current_mastery,
        target_mastery: target_mastery,
        remaining_mastery: remaining_mastery.round(3),
        estimated_days: estimated_days,
        estimated_hours: estimated_hours,
        estimated_completion_date: Date.today + estimated_days.days,
        learning_rate_per_day: learning_rate.round(4),
        confidence: calculate_timeline_confidence,
        assumptions: timeline_assumptions
      }
    else
      {
        status: 'insufficient_data',
        message: 'Need more study history to predict timeline',
        recommended_action: 'Continue studying for at least 7 more days'
      }
    end
  end

  # Predict course completion
  def predict_completion
    total_concepts = total_concepts_count
    tested_concepts = tested_concepts_count
    mastered_concepts = mastered_concepts_count

    current_rate = calculate_completion_rate
    remaining_concepts = total_concepts - tested_concepts

    if current_rate > 0
      estimated_days = (remaining_concepts / current_rate).ceil
      estimated_completion_date = Date.today + estimated_days.days

      {
        total_concepts: total_concepts,
        tested_concepts: tested_concepts,
        mastered_concepts: mastered_concepts,
        remaining_concepts: remaining_concepts,
        completion_percentage: ((tested_concepts.to_f / total_concepts) * 100).round(2),
        mastery_percentage: ((mastered_concepts.to_f / total_concepts) * 100).round(2),
        estimated_days_to_completion: estimated_days,
        estimated_completion_date: estimated_completion_date,
        concepts_per_day_rate: current_rate.round(2),
        recommended_daily_concepts: calculate_recommended_daily_concepts
      }
    else
      {
        status: 'not_started',
        total_concepts: total_concepts,
        message: 'Start studying to generate predictions'
      }
    end
  end

  # Predict goal achievement for specific targets
  def predict_goal_achievement(target_score: 80, target_date: nil)
    predicted_score = predict_exam_score[:predicted_score]
    mastery_timeline = predict_mastery_timeline(target_mastery: target_score / 100.0)

    if target_date
      days_until_target = (target_date.to_date - Date.today).to_i
      achievable = mastery_timeline[:estimated_days] && mastery_timeline[:estimated_days] <= days_until_target

      {
        target_score: target_score,
        predicted_score: predicted_score,
        target_date: target_date,
        days_remaining: days_until_target,
        estimated_days_needed: mastery_timeline[:estimated_days],
        achievable: achievable,
        probability: achievable ? calculate_achievement_probability(predicted_score, target_score) : 0.0,
        gap_analysis: analyze_gap(predicted_score, target_score),
        action_plan: generate_action_plan(predicted_score, target_score, days_until_target)
      }
    else
      {
        target_score: target_score,
        predicted_score: predicted_score,
        probability: calculate_achievement_probability(predicted_score, target_score),
        estimated_timeline: mastery_timeline,
        gap_analysis: analyze_gap(predicted_score, target_score)
      }
    end
  end

  # Assess risks to performance
  def assess_risks
    risks = []

    # Risk: Low study consistency
    consistency = calculate_study_consistency
    if consistency < 0.5
      risks << {
        type: 'consistency',
        severity: 'high',
        title: 'Low study consistency',
        description: "You're only studying #{(consistency * 100).round(1)}% of days. This may impact your progress.",
        mitigation: 'Try to study at least 5 days per week'
      }
    end

    # Risk: Many weak concepts
    weak_percentage = weak_concepts_percentage
    if weak_percentage > 30
      risks << {
        type: 'weak_concepts',
        severity: 'high',
        title: 'High number of weak concepts',
        description: "#{weak_percentage.round(1)}% of concepts are weak. This indicates comprehension issues.",
        mitigation: 'Focus on fundamentals and prerequisite concepts'
      }
    end

    # Risk: Declining trend
    trend = calculate_performance_trend
    if trend[:direction] == 'declining'
      risks << {
        type: 'declining_performance',
        severity: 'medium',
        title: 'Performance is declining',
        description: "Your recent performance is #{trend[:change].abs.round(1)}% lower than average.",
        mitigation: 'Review recent mistakes and adjust study approach'
      }
    end

    # Risk: Insufficient study time
    avg_daily_time = calculate_avg_daily_study_time
    if avg_daily_time < 15
      risks << {
        type: 'insufficient_time',
        severity: 'medium',
        title: 'Low study time',
        description: "You're studying an average of #{avg_daily_time.round(1)} minutes per day.",
        mitigation: 'Increase study time to at least 30 minutes per day'
      }
    end

    # Risk: Long gaps between sessions
    avg_gap = calculate_avg_session_gap
    if avg_gap > 3
      risks << {
        type: 'long_gaps',
        severity: 'low',
        title: 'Irregular study schedule',
        description: "Average #{avg_gap.round(1)} days between study sessions affects retention.",
        mitigation: 'Create a regular study schedule'
      }
    end

    {
      total_risks: risks.length,
      high_severity: risks.count { |r| r[:severity] == 'high' },
      medium_severity: risks.count { |r| r[:severity] == 'medium' },
      low_severity: risks.count { |r| r[:severity] == 'low' },
      risks: risks,
      overall_risk_level: calculate_overall_risk_level(risks)
    }
  end

  # Calculate improvement trajectory
  def calculate_improvement_trajectory
    historical_mastery = historical_data[:mastery_progression]
    return { status: 'insufficient_data' } if historical_mastery.empty?

    # Linear regression for trend
    trend = calculate_linear_trend(historical_mastery)

    # Project forward 30 days
    projections = (1..30).map do |days_ahead|
      projected_mastery = trend[:slope] * (historical_mastery.length + days_ahead) + trend[:intercept]
      {
        date: Date.today + days_ahead.days,
        projected_mastery: [projected_mastery, 1.0].min.round(3),
        confidence: calculate_projection_confidence(days_ahead)
      }
    end

    {
      current_trend: trend[:slope] > 0 ? 'improving' : 'declining',
      trend_strength: trend[:r_squared].round(3),
      daily_improvement_rate: trend[:slope].round(4),
      projections: projections,
      milestones: calculate_milestone_dates(projections)
    }
  end

  # Generate personalized recommendations
  def generate_recommendations
    predictions = {
      exam_score: predict_exam_score,
      timeline: predict_mastery_timeline,
      risks: assess_risks
    }

    recommendations = []

    # Score-based recommendations
    if predictions[:exam_score][:predicted_score] < 70
      recommendations << {
        priority: 'high',
        category: 'study_intensity',
        title: 'Increase study intensity',
        description: 'Your predicted score is below passing. Double your daily study time.',
        action: 'Study at least 1 hour daily, focus on weak concepts'
      }
    elsif predictions[:exam_score][:predicted_score] < 80
      recommendations << {
        priority: 'medium',
        category: 'focus_areas',
        title: 'Target weak areas',
        description: 'You\'re on track but need to strengthen weak concepts.',
        action: 'Spend 60% of time on concepts below 60% mastery'
      }
    end

    # Timeline recommendations
    if predictions[:timeline][:estimated_days] && predictions[:timeline][:estimated_days] > 90
      recommendations << {
        priority: 'medium',
        category: 'pace',
        title: 'Accelerate learning pace',
        description: "At current pace, you'll need #{predictions[:timeline][:estimated_days]} days.",
        action: 'Increase study frequency to 6-7 days per week'
      }
    end

    # Risk-based recommendations
    high_risks = predictions[:risks][:risks].select { |r| r[:severity] == 'high' }
    high_risks.each do |risk|
      recommendations << {
        priority: 'high',
        category: 'risk_mitigation',
        title: risk[:title],
        description: risk[:description],
        action: risk[:mitigation]
      }
    end

    # Optimization recommendations
    recommendations += optimization_recommendations

    {
      total_recommendations: recommendations.length,
      high_priority: recommendations.count { |r| r[:priority] == 'high' },
      recommendations: recommendations.sort_by { |r| r[:priority] == 'high' ? 0 : 1 }
    }
  end

  private

  def load_historical_data
    masteries = user_masteries_scope

    {
      mastery_progression: extract_mastery_progression(masteries),
      accuracy_progression: extract_accuracy_progression(masteries),
      study_time_progression: extract_study_time_progression(masteries),
      total_data_points: masteries.count
    }
  end

  def extract_mastery_progression(masteries)
    # Get daily average mastery levels
    dates = (30.days.ago.to_date..Date.today).to_a

    dates.map do |date|
      day_masteries = masteries.select do |m|
        m.last_tested_at && m.last_tested_at.to_date <= date
      end

      next nil if day_masteries.empty?

      {
        date: date,
        mastery: day_masteries.sum(&:mastery_level) / day_masteries.length.to_f
      }
    end.compact
  end

  def extract_accuracy_progression(masteries)
    dates = (30.days.ago.to_date..Date.today).to_a

    dates.map do |date|
      day_masteries = masteries.select do |m|
        m.last_tested_at && m.last_tested_at.to_date == date
      end

      next nil if day_masteries.empty?

      total = day_masteries.sum(&:attempts)
      correct = day_masteries.sum(&:correct_attempts)

      {
        date: date,
        accuracy: total.zero? ? 0.0 : (correct.to_f / total * 100)
      }
    end.compact
  end

  def extract_study_time_progression(masteries)
    dates = (30.days.ago.to_date..Date.today).to_a

    dates.map do |date|
      day_masteries = masteries.select do |m|
        m.last_tested_at && m.last_tested_at.to_date == date
      end

      next nil if day_masteries.empty?

      {
        date: date,
        minutes: day_masteries.sum(&:total_time_minutes)
      }
    end.compact
  end

  def calculate_current_mastery
    masteries = user_masteries_scope
    return 0.0 if masteries.empty?

    masteries.average(:mastery_level).to_f.round(3)
  end

  def calculate_current_accuracy
    masteries = user_masteries_scope
    total = masteries.sum(:attempts)
    return 0.0 if total.zero?

    (masteries.sum(:correct_attempts).to_f / total * 100).round(2)
  end

  def calculate_coverage
    total = total_concepts_count
    return 0.0 if total.zero?

    tested = tested_concepts_count
    (tested.to_f / total * 100).round(2)
  end

  def calculate_trend_adjustment
    recent = historical_data[:mastery_progression].last(7)
    return 0.0 if recent.length < 2

    trend = calculate_linear_trend(recent)

    # Positive trend = positive adjustment, capped at ±10 points
    adjustment = trend[:slope] * 30 * 100 # Project 30 days forward
    [[adjustment, 10].min, -10].max
  end

  def calculate_prediction_confidence
    data_points = historical_data[:total_data_points]

    case data_points
    when 0..10 then 0.3
    when 11..30 then 0.5
    when 31..60 then 0.7
    when 61..100 then 0.85
    else 0.95
    end
  end

  def score_to_grade(score)
    case score
    when 90..100 then 'A'
    when 80..89 then 'B'
    when 70..79 then 'C'
    when 60..69 then 'D'
    else 'F'
    end
  end

  def calculate_pass_probability(predicted_score)
    # Probability increases sigmoidally around passing score (60)
    # Using logistic function
    k = 0.15 # Steepness
    midpoint = 60 # Passing score

    probability = 1 / (1 + Math.exp(-k * (predicted_score - midpoint)))
    (probability * 100).round(2)
  end

  def calculate_learning_rate
    progression = historical_data[:mastery_progression]
    return 0.0 if progression.length < 2

    days = (progression.last[:date] - progression.first[:date]).to_i
    return 0.0 if days.zero?

    mastery_change = progression.last[:mastery] - progression.first[:mastery]
    mastery_change / days.to_f
  end

  def calculate_required_hours(remaining_mastery)
    # Estimate: 30 minutes per 0.1 mastery gain
    (remaining_mastery * 10 * 0.5).ceil
  end

  def calculate_timeline_confidence
    data_points = historical_data[:mastery_progression].length

    case data_points
    when 0..7 then 0.3
    when 8..14 then 0.6
    when 15..30 then 0.8
    else 0.9
    end
  end

  def timeline_assumptions
    [
      'Assumes current learning rate continues',
      'Assumes consistent study schedule',
      'Does not account for concept difficulty variation',
      'Based on linear progression model'
    ]
  end

  def total_concepts_count
    return 0 unless study_set

    KnowledgeNode.where(study_material_id: study_materials_ids)
                 .where(level: 'concept')
                 .count
  end

  def tested_concepts_count
    user_masteries_scope.where('attempts > 0').count
  end

  def mastered_concepts_count
    user_masteries_scope.where('mastery_level >= ?', 0.8).count
  end

  def calculate_completion_rate
    progression = historical_data[:mastery_progression]
    return 0.0 if progression.length < 2

    days = (progression.last[:date] - progression.first[:date]).to_i
    return 0.0 if days.zero?

    concepts_tested = tested_concepts_count
    concepts_tested / days.to_f
  end

  def calculate_recommended_daily_concepts
    remaining = total_concepts_count - tested_concepts_count
    return 0 if remaining.zero?

    # Recommend completing in 30 days
    (remaining / 30.0).ceil
  end

  def calculate_achievement_probability(predicted_score, target_score)
    difference = predicted_score - target_score

    # Sigmoid function for probability
    probability = 1 / (1 + Math.exp(-0.1 * difference))
    (probability * 100).round(2)
  end

  def analyze_gap(predicted_score, target_score)
    gap = target_score - predicted_score

    {
      score_gap: gap.round(2),
      percentage_gap: ((gap / target_score) * 100).round(2),
      severity: gap > 20 ? 'high' : (gap > 10 ? 'medium' : 'low'),
      estimated_effort: estimate_effort_for_gap(gap)
    }
  end

  def estimate_effort_for_gap(gap)
    # Estimate hours needed to close gap
    hours = (gap * 2).ceil # 2 hours per point

    {
      total_hours: hours,
      weeks_at_1h_daily: (hours / 7.0).ceil,
      weeks_at_2h_daily: (hours / 14.0).ceil
    }
  end

  def generate_action_plan(predicted_score, target_score, days_remaining)
    gap = target_score - predicted_score
    return { message: 'You\'re on track!' } if gap <= 0

    hours_needed = estimate_effort_for_gap(gap)[:total_hours]
    daily_hours = (hours_needed / days_remaining.to_f).ceil

    {
      gap: gap.round(2),
      days_remaining: days_remaining,
      required_daily_study: "#{daily_hours} hours",
      focus_areas: identify_focus_areas,
      weekly_goals: generate_weekly_goals(gap, days_remaining)
    }
  end

  def identify_focus_areas
    weak_concepts = user_masteries_scope
      .where('mastery_level < ?', 0.6)
      .order(:mastery_level)
      .limit(10)
      .includes(:knowledge_node)

    weak_concepts.map { |m| m.knowledge_node.name }
  end

  def generate_weekly_goals(gap, days_remaining)
    weeks = (days_remaining / 7.0).ceil
    points_per_week = (gap / weeks.to_f).ceil

    (1..weeks).map do |week|
      {
        week: week,
        target_improvement: "#{points_per_week} points",
        suggested_concepts: (points_per_week * 2) # Rough estimate
      }
    end
  end

  def calculate_study_consistency
    dates = user_masteries_scope
      .where('last_tested_at >= ?', 30.days.ago)
      .select('DISTINCT DATE(last_tested_at)')
      .count

    dates / 30.0
  end

  def weak_concepts_percentage
    total = user_masteries_scope.count
    return 0.0 if total.zero?

    weak = user_masteries_scope.where('mastery_level < ?', 0.6).count
    (weak.to_f / total * 100).round(2)
  end

  def calculate_performance_trend
    recent = historical_data[:mastery_progression].last(7)
    older = historical_data[:mastery_progression].first(7)

    return { direction: 'stable', change: 0.0 } if recent.empty? || older.empty?

    recent_avg = recent.sum { |r| r[:mastery] } / recent.length.to_f
    older_avg = older.sum { |r| r[:mastery] } / older.length.to_f

    change = ((recent_avg - older_avg) * 100).round(2)

    {
      direction: change > 5 ? 'improving' : (change < -5 ? 'declining' : 'stable'),
      change: change
    }
  end

  def calculate_avg_daily_study_time
    time_data = historical_data[:study_time_progression]
    return 0.0 if time_data.empty?

    total_minutes = time_data.sum { |d| d[:minutes] }
    (total_minutes / time_data.length.to_f).round(1)
  end

  def calculate_avg_session_gap
    dates = user_masteries_scope
      .where('last_tested_at IS NOT NULL')
      .select('DISTINCT DATE(last_tested_at) as d')
      .order('d ASC')
      .pluck('d')

    return 0.0 if dates.length < 2

    gaps = dates.each_cons(2).map { |d1, d2| (d2 - d1).to_i }
    gaps.sum / gaps.length.to_f
  end

  def calculate_overall_risk_level(risks)
    high = risks.count { |r| r[:severity] == 'high' }
    medium = risks.count { |r| r[:severity] == 'medium' }

    if high >= 2
      'high'
    elsif high == 1 || medium >= 3
      'medium'
    else
      'low'
    end
  end

  def calculate_linear_trend(data_points)
    return { slope: 0, intercept: 0, r_squared: 0 } if data_points.empty?

    n = data_points.length
    x_values = (1..n).to_a
    y_values = data_points.map { |p| p[:mastery] || p[:accuracy] || 0 }

    x_mean = x_values.sum / n.to_f
    y_mean = y_values.sum / n.to_f

    numerator = x_values.zip(y_values).sum { |x, y| (x - x_mean) * (y - y_mean) }
    denominator = x_values.sum { |x| (x - x_mean)**2 }

    slope = denominator.zero? ? 0 : numerator / denominator
    intercept = y_mean - (slope * x_mean)

    # Calculate R²
    ss_tot = y_values.sum { |y| (y - y_mean)**2 }
    ss_res = x_values.zip(y_values).sum { |x, y| (y - (slope * x + intercept))**2 }
    r_squared = ss_tot.zero? ? 0 : 1 - (ss_res / ss_tot)

    { slope: slope, intercept: intercept, r_squared: [r_squared, 0].max }
  end

  def calculate_projection_confidence(days_ahead)
    # Confidence decreases with projection distance
    base_confidence = calculate_prediction_confidence

    decay_factor = 1 - (days_ahead / 30.0) * 0.3
    (base_confidence * [decay_factor, 0.3].max).round(2)
  end

  def calculate_milestone_dates(projections)
    milestones = [0.5, 0.6, 0.7, 0.8, 0.9]

    milestones.map do |target|
      projection = projections.find { |p| p[:projected_mastery] >= target }

      next nil unless projection

      {
        mastery_level: target,
        estimated_date: projection[:date],
        days_from_now: (projection[:date] - Date.today).to_i
      }
    end.compact
  end

  def optimization_recommendations
    recommendations = []

    # Time optimization
    time_analysis = TimeBasedAnalysisService.new(user, study_set: study_set).time_of_day_analysis
    best_time = time_analysis[:best_time_of_day]

    if best_time
      recommendations << {
        priority: 'medium',
        category: 'optimization',
        title: 'Study during peak performance time',
        description: "Your #{best_time[:period]} performance is best.",
        action: "Schedule difficult topics during #{best_time[:period]}"
      }
    end

    # Concept prioritization
    weak_count = user_masteries_scope.where('mastery_level < ?', 0.5).count
    if weak_count > 5
      recommendations << {
        priority: 'high',
        category: 'prioritization',
        title: 'Focus on fundamental concepts',
        description: "You have #{weak_count} weak concepts that need attention.",
        action: 'Master prerequisite concepts before advancing'
      }
    end

    recommendations
  end

  def user_masteries_scope
    scope = UserMastery.where(user_id: user.id)
    scope = scope.joins(:knowledge_node)
                 .where(knowledge_nodes: { study_material_id: study_materials_ids }) if study_set
    scope
  end

  def study_materials_ids
    @study_materials_ids ||= study_set ? study_set.study_materials.pluck(:id) : []
  end
end
