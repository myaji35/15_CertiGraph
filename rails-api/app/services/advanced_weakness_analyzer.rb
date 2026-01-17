class AdvancedWeaknessAnalyzer
  # Multi-dimensional weakness analysis with ML integration

  def initialize(user, study_material = nil)
    @user = user
    @study_material = study_material
    @ml_detector = MlPatternDetector.new(user)
  end

  # Comprehensive multi-dimensional analysis
  def analyze
    {
      multidimensional_analysis: multidimensional_weakness_analysis,
      severity_scores: calculate_severity_scores,
      priority_ranking: calculate_priority_ranking,
      peer_comparison: compare_with_peers,
      improvement_tracking: track_improvement_over_time,
      ml_insights: ml_pattern_insights
    }
  end

  # Multi-dimensional weakness analysis
  def multidimensional_weakness_analysis
    {
      by_concept: analyze_by_concept,
      by_difficulty: analyze_by_difficulty,
      by_question_type: analyze_by_question_type,
      by_topic: analyze_by_topic,
      by_time_of_day: analyze_by_time_of_day,
      by_session_length: analyze_by_session_length
    }
  end

  # Weakness severity score (0-100)
  def calculate_severity_scores
    concepts = analyze_by_concept

    concepts.map do |concept_id, data|
      severity = calculate_concept_severity(data)

      {
        concept_id: concept_id,
        concept_name: data[:concept_name],
        severity_score: severity,
        severity_level: categorize_severity(severity),
        contributing_factors: identify_severity_factors(data)
      }
    end.sort_by { |c| -c[:severity_score] }
  end

  # Priority ranking for study
  def calculate_priority_ranking
    severity_scores = calculate_severity_scores

    severity_scores.map.with_index do |item, index|
      priority_score = calculate_priority_score(item)

      {
        rank: index + 1,
        concept_id: item[:concept_id],
        concept_name: item[:concept_name],
        priority_score: priority_score,
        severity: item[:severity_score],
        urgency: calculate_urgency(item),
        impact: calculate_impact(item),
        estimated_study_hours: estimate_study_hours(item)
      }
    end.sort_by { |i| -i[:priority_score] }
  end

  # Compare with similar users
  def compare_with_peers
    similar_users = find_similar_users

    return { message: 'Not enough peer data' } if similar_users.empty?

    {
      peer_count: similar_users.length,
      user_percentile: calculate_percentile_rank(similar_users),
      comparison_metrics: compare_metrics_with_peers(similar_users),
      relative_strengths: identify_relative_strengths(similar_users),
      relative_weaknesses: identify_relative_weaknesses(similar_users)
    }
  end

  # Track improvement over time
  def track_improvement_over_time
    {
      weekly_trends: calculate_weekly_trends,
      monthly_trends: calculate_monthly_trends,
      concept_improvements: track_concept_improvements,
      overall_trajectory: calculate_overall_trajectory,
      milestone_achievements: identify_milestones
    }
  end

  # ML-based insights
  def ml_pattern_insights
    patterns = @ml_detector.detect_error_patterns

    {
      error_clusters: patterns[:clustering_patterns],
      predicted_patterns: patterns[:classification_patterns],
      time_trends: patterns[:time_series_patterns],
      anomalies: patterns[:anomalies],
      future_predictions: @ml_detector.predict_future_patterns
    }
  end

  # Generate comprehensive weakness report
  def generate_report(report_type: 'comprehensive')
    analysis = analyze

    report = WeaknessReport.create!(
      user: @user,
      study_material: @study_material,
      report_type: report_type,
      period_start: 30.days.ago.to_date,
      period_end: Date.today,
      weakness_by_concept: format_weakness_by_concept(analysis),
      weakness_by_difficulty: format_weakness_by_difficulty(analysis),
      weakness_by_question_type: format_weakness_by_question_type(analysis),
      weakness_by_topic: format_weakness_by_topic(analysis),
      overall_weakness_score: calculate_overall_weakness_score(analysis),
      critical_weaknesses: extract_critical_weaknesses(analysis),
      moderate_weaknesses: extract_moderate_weaknesses(analysis),
      minor_weaknesses: extract_minor_weaknesses(analysis),
      improvement_over_time: analysis[:improvement_tracking][:weekly_trends],
      improvement_percentage: analysis[:improvement_tracking][:overall_trajectory][:improvement_rate],
      improvement_by_concept: analysis[:improvement_tracking][:concept_improvements],
      peer_comparison: analysis[:peer_comparison],
      percentile_rank: analysis[:peer_comparison][:user_percentile],
      priority_recommendations: generate_priority_recommendations(analysis),
      learning_path_suggestions: generate_learning_path_suggestions(analysis),
      estimated_study_hours: calculate_total_study_hours(analysis),
      heatmap_data: generate_heatmap_data(analysis),
      trend_chart_data: generate_trend_chart_data(analysis),
      comparison_chart_data: generate_comparison_chart_data(analysis),
      statistics: compile_statistics(analysis)
    )

    # Generate PDF asynchronously
    GenerateWeaknessReportPdfJob.perform_later(report.id) if report_type != 'quick'

    report
  end

  private

  # Dimensional analysis methods
  def analyze_by_concept
    wrong_answers = fetch_wrong_answers
    concept_groups = wrong_answers.group_by do |wa|
      wa.question.question_concepts.first&.knowledge_node
    end

    concept_groups.transform_values do |errors|
      total_attempts = errors.sum { |e| e.attempt_count || 1 }
      concept_id = errors.first.question.question_concepts.first&.knowledge_node_id

      {
        concept_id: concept_id,
        concept_name: errors.first.question.question_concepts.first&.knowledge_node&.name || 'Unknown',
        error_count: errors.count,
        total_attempts: total_attempts,
        avg_attempts: (total_attempts.to_f / errors.count).round(2),
        recent_errors: errors.count { |e| e.last_attempted_at > 7.days.ago },
        difficulty_avg: errors.map { |e| e.question.difficulty || 3 }.sum.to_f / errors.count
      }
    end
  end

  def analyze_by_difficulty
    wrong_answers = fetch_wrong_answers

    difficulty_groups = wrong_answers.group_by { |wa| wa.question.difficulty || 3 }

    difficulty_groups.transform_values do |errors|
      {
        error_count: errors.count,
        percentage: (errors.count.to_f / wrong_answers.count * 100).round(2),
        topics: errors.map { |e| e.question.topic }.uniq,
        avg_attempts: errors.sum { |e| e.attempt_count || 1 }.to_f / errors.count
      }
    end
  end

  def analyze_by_question_type
    wrong_answers = fetch_wrong_answers.includes(question: :question_passages)

    {
      with_passage: count_by_type(wrong_answers.select { |wa| wa.question.question_passages.any? }),
      without_passage: count_by_type(wrong_answers.reject { |wa| wa.question.question_passages.any? }),
      multi_step: count_by_type(wrong_answers.select { |wa| (wa.question.content&.length || 0) > 500 }),
      single_step: count_by_type(wrong_answers.reject { |wa| (wa.question.content&.length || 0) > 500 })
    }
  end

  def analyze_by_topic
    wrong_answers = fetch_wrong_answers

    topic_groups = wrong_answers.group_by { |wa| wa.question.topic }

    topic_groups.transform_values do |errors|
      {
        error_count: errors.count,
        percentage: (errors.count.to_f / wrong_answers.count * 100).round(2),
        difficulty_avg: errors.map { |e| e.question.difficulty || 3 }.sum.to_f / errors.count,
        recent_trend: errors.count { |e| e.last_attempted_at > 7.days.ago } <=> errors.count { |e| e.last_attempted_at.between?(14.days.ago, 7.days.ago) }
      }
    end
  end

  def analyze_by_time_of_day
    wrong_answers = fetch_wrong_answers

    time_groups = wrong_answers.group_by { |wa| wa.last_attempted_at.hour / 4 } # 6 time blocks

    time_groups.transform_keys do |block|
      case block
      when 0 then 'Early Morning (0-4am)'
      when 1 then 'Morning (4-8am)'
      when 2 then 'Late Morning (8-12pm)'
      when 3 then 'Afternoon (12-4pm)'
      when 4 then 'Evening (4-8pm)'
      when 5 then 'Night (8pm-12am)'
      end
    end.transform_values { |errors| { error_count: errors.count, percentage: (errors.count.to_f / wrong_answers.count * 100).round(2) } }
  end

  def analyze_by_session_length
    sessions = @user.exam_sessions.includes(:exam_answers).where.not(completed_at: nil)

    sessions_with_errors = sessions.select do |session|
      session.exam_answers.where(is_correct: false).any?
    end

    {
      short_sessions: sessions_with_errors.count { |s| session_duration(s) < 1800 },
      medium_sessions: sessions_with_errors.count { |s| session_duration(s).between?(1800, 3600) },
      long_sessions: sessions_with_errors.count { |s| session_duration(s) > 3600 }
    }
  end

  # Severity calculation
  def calculate_concept_severity(concept_data)
    # Factors: error_count, recency, difficulty, attempts
    error_weight = [concept_data[:error_count] * 10, 50].min
    recency_weight = [concept_data[:recent_errors] * 15, 30].min
    difficulty_weight = concept_data[:difficulty_avg] * 5
    persistence_weight = [concept_data[:avg_attempts] * 8, 20].min

    (error_weight + recency_weight + difficulty_weight + persistence_weight).round.clamp(0, 100)
  end

  def categorize_severity(score)
    case score
    when 0..30 then 'minor'
    when 31..60 then 'moderate'
    when 61..80 then 'significant'
    else 'critical'
    end
  end

  def identify_severity_factors(concept_data)
    factors = []
    factors << 'High error frequency' if concept_data[:error_count] > 5
    factors << 'Recent struggles' if concept_data[:recent_errors] > 3
    factors << 'High difficulty content' if concept_data[:difficulty_avg] > 4
    factors << 'Persistent errors' if concept_data[:avg_attempts] > 2

    factors
  end

  # Priority calculation
  def calculate_priority_score(item)
    severity = item[:severity_score]
    urgency = calculate_urgency(item)
    impact = calculate_impact(item)

    (severity * 0.4 + urgency * 0.3 + impact * 0.3).round
  end

  def calculate_urgency(item)
    # Based on recency and exam proximity
    # For now, simplified to severity-based
    (item[:severity_score] * 0.8).round
  end

  def calculate_impact(item)
    # Based on concept importance and dependencies
    # Simplified version
    (item[:severity_score] * 0.9).round
  end

  def estimate_study_hours(item)
    severity = item[:severity_score]

    case severity
    when 0..30 then 1..2
    when 31..60 then 3..5
    when 61..80 then 6..10
    else 10..15
    end
  end

  # Peer comparison
  def find_similar_users
    # Find users with similar study materials and activity level
    user_exam_count = @user.exam_answers.count

    User.joins(:exam_answers)
        .where.not(id: @user.id)
        .group('users.id')
        .having('COUNT(exam_answers.id) BETWEEN ? AND ?', user_exam_count * 0.7, user_exam_count * 1.3)
        .limit(50)
  end

  def calculate_percentile_rank(similar_users)
    user_accuracy = calculate_user_accuracy(@user)

    users_with_accuracy = similar_users.map { |u| calculate_user_accuracy(u) }
    users_with_accuracy << user_accuracy

    sorted = users_with_accuracy.sort
    rank = sorted.index(user_accuracy)

    ((rank.to_f / sorted.length) * 100).round
  end

  def compare_metrics_with_peers(similar_users)
    user_metrics = calculate_user_metrics(@user)
    peer_metrics = similar_users.map { |u| calculate_user_metrics(u) }

    avg_peer_metrics = {
      accuracy: peer_metrics.sum { |m| m[:accuracy] } / peer_metrics.length,
      avg_time: peer_metrics.sum { |m| m[:avg_time] } / peer_metrics.length,
      sessions_count: peer_metrics.sum { |m| m[:sessions_count] } / peer_metrics.length
    }

    {
      user: user_metrics,
      peer_average: avg_peer_metrics,
      comparison: {
        accuracy_diff: user_metrics[:accuracy] - avg_peer_metrics[:accuracy],
        time_diff: user_metrics[:avg_time] - avg_peer_metrics[:avg_time]
      }
    }
  end

  def identify_relative_strengths(similar_users)
    user_concepts = @user.user_masteries.where('mastery_level > 0.7')

    user_concepts.map do |mastery|
      {
        concept: mastery.knowledge_node.name,
        user_mastery: mastery.mastery_level,
        percentile: 75 # Simplified
      }
    end.take(5)
  end

  def identify_relative_weaknesses(similar_users)
    user_concepts = @user.user_masteries.where('mastery_level < 0.5')

    user_concepts.map do |mastery|
      {
        concept: mastery.knowledge_node.name,
        user_mastery: mastery.mastery_level,
        percentile: 25 # Simplified
      }
    end.take(5)
  end

  # Improvement tracking
  def calculate_weekly_trends
    (0..4).map do |weeks_ago|
      start_date = (weeks_ago + 1).weeks.ago
      end_date = weeks_ago.weeks.ago

      accuracy = calculate_accuracy_for_period(start_date, end_date)

      {
        week: "#{weeks_ago} weeks ago",
        period: "#{start_date.to_date} to #{end_date.to_date}",
        accuracy: accuracy,
        attempts: count_attempts_for_period(start_date, end_date)
      }
    end.reverse
  end

  def calculate_monthly_trends
    (0..2).map do |months_ago|
      start_date = (months_ago + 1).months.ago
      end_date = months_ago.months.ago

      {
        month: "#{months_ago} months ago",
        accuracy: calculate_accuracy_for_period(start_date, end_date),
        improvement: calculate_improvement_for_period(start_date, end_date)
      }
    end.reverse
  end

  def track_concept_improvements
    @user.user_masteries.map do |mastery|
      history = mastery.history || []

      next if history.empty?

      {
        concept: mastery.knowledge_node.name,
        current_level: mastery.mastery_level,
        previous_level: history.last['mastery_level'],
        improvement: mastery.mastery_level - history.last['mastery_level'].to_f
      }
    end.compact
  end

  def calculate_overall_trajectory
    weekly = calculate_weekly_trends

    return { trend: 'insufficient_data', improvement_rate: 0 } if weekly.length < 2

    first_accuracy = weekly.first[:accuracy]
    last_accuracy = weekly.last[:accuracy]

    improvement_rate = last_accuracy - first_accuracy

    {
      trend: improvement_rate > 5 ? 'improving' : improvement_rate < -5 ? 'declining' : 'stable',
      improvement_rate: improvement_rate.round(2),
      velocity: (improvement_rate / weekly.length).round(2)
    }
  end

  def identify_milestones
    milestones = []

    # Check for mastery achievements
    recent_masteries = @user.user_masteries.where('mastery_level >= 0.8 AND updated_at > ?', 30.days.ago)
    if recent_masteries.any?
      milestones << {
        type: 'mastery',
        description: "Mastered #{recent_masteries.count} concepts",
        achieved_at: recent_masteries.maximum(:updated_at)
      }
    end

    milestones
  end

  # Helper methods
  def fetch_wrong_answers
    if @study_material
      @user.wrong_answers.joins(:question).where(questions: { study_material_id: @study_material.id })
    else
      @user.wrong_answers
    end.includes(question: [:question_concepts, :question_passages])
  end

  def count_by_type(errors)
    {
      count: errors.count,
      percentage: errors.any? ? (errors.count.to_f / fetch_wrong_answers.count * 100).round(2) : 0
    }
  end

  def session_duration(session)
    return 0 unless session.completed_at && session.started_at

    (session.completed_at - session.started_at).to_i
  end

  def calculate_user_accuracy(user)
    total = user.exam_answers.count
    return 0.0 if total.zero?

    correct = user.exam_answers.where(is_correct: true).count
    (correct.to_f / total * 100).round(2)
  end

  def calculate_user_metrics(user)
    {
      accuracy: calculate_user_accuracy(user),
      avg_time: user.exam_answers.average(:time_spent)&.to_i || 0,
      sessions_count: user.exam_sessions.count
    }
  end

  def calculate_accuracy_for_period(start_date, end_date)
    answers = @user.exam_answers.where(created_at: start_date..end_date)
    return 0.0 if answers.count.zero?

    correct = answers.where(is_correct: true).count
    (correct.to_f / answers.count * 100).round(2)
  end

  def count_attempts_for_period(start_date, end_date)
    @user.exam_answers.where(created_at: start_date..end_date).count
  end

  def calculate_improvement_for_period(start_date, end_date)
    mid_point = start_date + (end_date - start_date) / 2

    first_half = calculate_accuracy_for_period(start_date, mid_point)
    second_half = calculate_accuracy_for_period(mid_point, end_date)

    (second_half - first_half).round(2)
  end

  # Report formatting methods
  def format_weakness_by_concept(analysis)
    analysis[:multidimensional_analysis][:by_concept]
  end

  def format_weakness_by_difficulty(analysis)
    analysis[:multidimensional_analysis][:by_difficulty]
  end

  def format_weakness_by_question_type(analysis)
    analysis[:multidimensional_analysis][:by_question_type]
  end

  def format_weakness_by_topic(analysis)
    analysis[:multidimensional_analysis][:by_topic]
  end

  def calculate_overall_weakness_score(analysis)
    severity_scores = analysis[:severity_scores]
    return 0 if severity_scores.empty?

    avg_severity = severity_scores.sum { |s| s[:severity_score] } / severity_scores.length
    avg_severity.round
  end

  def extract_critical_weaknesses(analysis)
    analysis[:severity_scores].select { |s| s[:severity_level] == 'critical' }
  end

  def extract_moderate_weaknesses(analysis)
    analysis[:severity_scores].select { |s| s[:severity_level] == 'moderate' }
  end

  def extract_minor_weaknesses(analysis)
    analysis[:severity_scores].select { |s| s[:severity_level] == 'minor' }
  end

  def generate_priority_recommendations(analysis)
    analysis[:priority_ranking].take(5).map do |item|
      {
        concept: item[:concept_name],
        priority: item[:rank],
        action: "Focus on #{item[:concept_name]} - estimated #{item[:estimated_study_hours]} hours",
        severity: item[:severity]
      }
    end
  end

  def generate_learning_path_suggestions(analysis)
    # Use existing learning path generation
    priority_concepts = analysis[:priority_ranking].take(3)

    priority_concepts.map do |concept|
      {
        concept_id: concept[:concept_id],
        concept_name: concept[:concept_name],
        suggested_order: concept[:rank],
        estimated_hours: concept[:estimated_study_hours]
      }
    end
  end

  def calculate_total_study_hours(analysis)
    analysis[:priority_ranking].sum { |item| item[:estimated_study_hours].is_a?(Range) ? item[:estimated_study_hours].min : item[:estimated_study_hours] }
  end

  def generate_heatmap_data(analysis)
    # Format data for heatmap visualization
    by_concept = analysis[:multidimensional_analysis][:by_concept]
    by_difficulty = analysis[:multidimensional_analysis][:by_difficulty]

    {
      concepts: by_concept.map { |k, v| { name: v[:concept_name], value: v[:error_count] } },
      difficulties: by_difficulty.map { |k, v| { level: k, value: v[:error_count] } }
    }
  end

  def generate_trend_chart_data(analysis)
    analysis[:improvement_tracking][:weekly_trends]
  end

  def generate_comparison_chart_data(analysis)
    peer_data = analysis[:peer_comparison][:comparison_metrics]

    [
      { category: 'User', accuracy: peer_data[:user][:accuracy] },
      { category: 'Peers', accuracy: peer_data[:peer_average][:accuracy] }
    ]
  end

  def compile_statistics(analysis)
    {
      total_weaknesses: analysis[:severity_scores].length,
      critical_count: extract_critical_weaknesses(analysis).length,
      overall_severity: calculate_overall_weakness_score(analysis),
      improvement_rate: analysis[:improvement_tracking][:overall_trajectory][:improvement_rate],
      percentile: analysis[:peer_comparison][:user_percentile]
    }
  end
end
