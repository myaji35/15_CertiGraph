# Service for generating comprehensive performance reports
class PerformanceReportService
  attr_reader :user, :study_set, :date_range

  def initialize(user, study_set: nil, start_date: 30.days.ago, end_date: Date.today)
    @user = user
    @study_set = study_set
    @date_range = start_date..end_date
  end

  # Generate comprehensive report
  def generate_report
    {
      user_info: user_info,
      overall_summary: overall_summary,
      subject_analysis: subject_analysis,
      chapter_analysis: chapter_analysis,
      concept_analysis: concept_analysis,
      strengths_and_weaknesses: strengths_and_weaknesses,
      progress_tracking: progress_tracking,
      comparative_analysis: comparative_analysis,
      recommendations: recommendations,
      generated_at: Time.current
    }
  end

  # Quick summary for dashboard
  def quick_summary
    masteries = user_masteries_scope

    {
      total_concepts: masteries.count,
      mastered: masteries.mastered_areas.count,
      learning: masteries.learning_areas.count,
      weak: masteries.weak_areas.count,
      untested: masteries.where(status: 'untested').count,
      overall_mastery: calculate_overall_mastery,
      overall_accuracy: calculate_overall_accuracy,
      total_study_time: total_study_time_minutes,
      completion_rate: completion_rate,
      recent_performance_trend: recent_performance_trend
    }
  end

  # Subject-specific breakdown
  def subject_breakdown
    nodes = knowledge_nodes_scope
    nodes.where(level: 'subject').map do |subject|
      subject_masteries = user_masteries_for_node_descendants(subject)

      {
        subject_id: subject.id,
        subject_name: subject.name,
        total_concepts: subject_masteries.count,
        mastered: subject_masteries.mastered_areas.count,
        accuracy: calculate_accuracy(subject_masteries),
        mastery_level: calculate_average_mastery(subject_masteries),
        progress_percentage: progress_percentage(subject_masteries),
        estimated_hours_remaining: estimated_hours_remaining(subject_masteries)
      }
    end
  end

  # Chapter-specific breakdown
  def chapter_breakdown
    nodes = knowledge_nodes_scope
    nodes.where(level: 'chapter').map do |chapter|
      chapter_masteries = user_masteries_for_node_descendants(chapter)

      {
        chapter_id: chapter.id,
        chapter_name: chapter.name,
        parent_subject: chapter.parent_name,
        total_concepts: chapter_masteries.count,
        mastered: chapter_masteries.mastered_areas.count,
        accuracy: calculate_accuracy(chapter_masteries),
        mastery_level: calculate_average_mastery(chapter_masteries),
        difficulty: chapter.difficulty,
        importance: chapter.importance,
        study_time: chapter_masteries.sum(:total_time_minutes)
      }
    end
  end

  # Detailed concept analysis
  def concept_analysis
    masteries = user_masteries_scope.includes(:knowledge_node)

    masteries.map do |mastery|
      {
        concept_id: mastery.knowledge_node_id,
        concept_name: mastery.knowledge_node.name,
        category: mastery.knowledge_node.level,
        mastery_level: mastery.mastery_level,
        status: mastery.status,
        color: mastery.color,
        attempts: mastery.attempts,
        correct: mastery.correct_attempts,
        accuracy: mastery.accuracy,
        last_tested: mastery.last_tested_at,
        days_since_test: mastery.days_since_last_test,
        study_time: mastery.total_time_minutes,
        recent_trend: recent_trend_for_mastery(mastery),
        difficulty_rating: mastery.difficulty_rating,
        retention_score: mastery.retention_score
      }
    end
  end

  # Top strengths (best performing concepts)
  def top_strengths(limit: 10)
    user_masteries_scope
      .where('mastery_level >= ?', 0.8)
      .where('attempts >= ?', 3)
      .order(mastery_level: :desc, accuracy: :desc)
      .limit(limit)
      .includes(:knowledge_node)
      .map { |m| concept_summary(m) }
  end

  # Top weaknesses (worst performing concepts)
  def top_weaknesses(limit: 10)
    user_masteries_scope
      .where('mastery_level < ?', 0.6)
      .where('attempts >= ?', 1)
      .order(mastery_level: :asc)
      .limit(limit)
      .includes(:knowledge_node)
      .map { |m| concept_summary(m) }
  end

  # Recently improved concepts
  def recent_improvements(days: 7, limit: 10)
    masteries = user_masteries_scope.includes(:knowledge_node)

    improvements = masteries.select do |m|
      recent = m.recent_performance(days: days)
      next false if recent.empty? || m.history.length < 2

      recent_avg = recent.sum { |h| h['mastery_level'] || 0 } / recent.length.to_f
      older_history = m.history[0...-recent.length]
      next false if older_history.empty?

      older_avg = older_history.sum { |h| h['mastery_level'] || 0 } / older_history.length.to_f
      recent_avg > older_avg + 0.1
    end

    improvements.first(limit).map { |m| concept_summary(m) }
  end

  # Goal achievement tracking
  def goal_tracking(target_mastery: 0.8, target_date: nil)
    current_mastery = calculate_overall_mastery
    current_completion = completion_rate

    days_elapsed = (Date.today - date_range.begin).to_i
    mastery_rate = days_elapsed > 0 ? current_mastery / days_elapsed : 0

    remaining_mastery = [target_mastery - current_mastery, 0].max
    estimated_days = mastery_rate > 0 ? (remaining_mastery / mastery_rate).ceil : nil

    {
      current_mastery: current_mastery,
      target_mastery: target_mastery,
      progress_percentage: (current_mastery / target_mastery * 100).round(2),
      current_completion: current_completion,
      days_elapsed: days_elapsed,
      estimated_days_remaining: estimated_days,
      estimated_completion_date: estimated_days ? Date.today + estimated_days : nil,
      target_date: target_date,
      on_track: target_date ? (estimated_days && Date.today + estimated_days <= target_date) : nil,
      daily_mastery_rate: mastery_rate.round(4)
    }
  end

  private

  def user_info
    {
      user_id: user.id,
      user_name: user.name,
      user_email: user.email,
      study_set_id: study_set&.id,
      study_set_title: study_set&.title
    }
  end

  def overall_summary
    {
      overall_mastery_level: calculate_overall_mastery,
      overall_accuracy: calculate_overall_accuracy,
      total_concepts: user_masteries_scope.count,
      mastered_count: user_masteries_scope.mastered_areas.count,
      learning_count: user_masteries_scope.learning_areas.count,
      weak_count: user_masteries_scope.weak_areas.count,
      total_attempts: user_masteries_scope.sum(:attempts),
      total_correct: user_masteries_scope.sum(:correct_attempts),
      total_study_minutes: total_study_time_minutes,
      completion_rate: completion_rate,
      performance_grade: performance_grade(calculate_overall_mastery)
    }
  end

  def subject_analysis
    subject_breakdown
  end

  def chapter_analysis
    chapter_breakdown
  end

  def strengths_and_weaknesses
    {
      top_strengths: top_strengths(limit: 5),
      top_weaknesses: top_weaknesses(limit: 5),
      recent_improvements: recent_improvements(days: 7, limit: 5),
      needs_attention: concepts_needing_attention
    }
  end

  def progress_tracking
    {
      daily_progress: daily_progress_data,
      weekly_progress: weekly_progress_summary,
      completion_tracking: completion_tracking_data,
      goal_tracking: goal_tracking(target_mastery: 0.8)
    }
  end

  def comparative_analysis
    all_users_data = calculate_comparative_stats

    {
      user_mastery: calculate_overall_mastery,
      platform_average: all_users_data[:avg_mastery],
      percentile_rank: calculate_percentile_rank,
      ranking_position: calculate_ranking_position,
      comparison_summary: comparison_summary(all_users_data)
    }
  end

  def recommendations
    {
      focus_areas: top_weaknesses(limit: 3).map { |c| c[:name] },
      suggested_study_time: suggested_daily_study_time,
      optimal_study_times: optimal_study_times,
      next_review_concepts: concepts_due_for_review,
      motivational_message: motivational_message
    }
  end

  def user_masteries_scope
    scope = UserMastery.where(user_id: user.id)
    scope = scope.joins(:knowledge_node).where(knowledge_nodes: { study_material_id: study_materials_ids }) if study_set
    scope
  end

  def knowledge_nodes_scope
    return KnowledgeNode.none unless study_set
    KnowledgeNode.where(study_material_id: study_materials_ids)
  end

  def study_materials_ids
    @study_materials_ids ||= study_set ? study_set.study_materials.pluck(:id) : []
  end

  def user_masteries_for_node_descendants(node)
    # Get all descendant nodes
    descendant_ids = knowledge_nodes_scope
      .where('parent_name = ? OR name = ?', node.name, node.name)
      .pluck(:id)

    user_masteries_scope.where(knowledge_node_id: descendant_ids)
  end

  def calculate_overall_mastery
    masteries = user_masteries_scope
    return 0.0 if masteries.empty?

    masteries.average(:mastery_level).to_f.round(3)
  end

  def calculate_overall_accuracy
    masteries = user_masteries_scope
    total_attempts = masteries.sum(:attempts)
    return 0.0 if total_attempts.zero?

    (masteries.sum(:correct_attempts).to_f / total_attempts * 100).round(2)
  end

  def calculate_accuracy(masteries)
    total_attempts = masteries.sum(:attempts)
    return 0.0 if total_attempts.zero?

    (masteries.sum(:correct_attempts).to_f / total_attempts * 100).round(2)
  end

  def calculate_average_mastery(masteries)
    return 0.0 if masteries.empty?
    (masteries.sum(:mastery_level) / masteries.count.to_f).round(3)
  end

  def total_study_time_minutes
    user_masteries_scope.sum(:total_time_minutes)
  end

  def completion_rate
    total = knowledge_nodes_scope.where(level: 'concept').count
    return 0.0 if total.zero?

    tested = user_masteries_scope.where('attempts > 0').count
    (tested.to_f / total * 100).round(2)
  end

  def progress_percentage(masteries)
    return 0.0 if masteries.empty?
    mastered = masteries.mastered_areas.count
    (mastered.to_f / masteries.count * 100).round(2)
  end

  def estimated_hours_remaining(masteries)
    weak_and_learning = masteries.where(status: ['weak', 'learning']).count
    (weak_and_learning * 0.5).round(1) # Estimate 30 minutes per concept
  end

  def recent_performance_trend
    recent_masteries = user_masteries_scope.where('last_tested_at > ?', 7.days.ago)
    return 'no_data' if recent_masteries.empty?

    recent_accuracy = calculate_accuracy(recent_masteries)
    overall_accuracy = calculate_overall_accuracy

    if recent_accuracy > overall_accuracy + 5
      'improving'
    elsif recent_accuracy < overall_accuracy - 5
      'declining'
    else
      'stable'
    end
  end

  def recent_trend_for_mastery(mastery)
    recent = mastery.recent_performance(days: 7)
    return 'no_data' if recent.length < 2

    recent_avg = recent.last(3).sum { |h| h['mastery_level'] || 0 } / [recent.length, 3].min.to_f
    older_avg = recent.first(3).sum { |h| h['mastery_level'] || 0 } / [recent.length, 3].min.to_f

    if recent_avg > older_avg + 0.1
      'improving'
    elsif recent_avg < older_avg - 0.1
      'declining'
    else
      'stable'
    end
  end

  def concept_summary(mastery)
    {
      id: mastery.id,
      concept_id: mastery.knowledge_node_id,
      name: mastery.knowledge_node.name,
      level: mastery.knowledge_node.level,
      mastery_level: mastery.mastery_level,
      accuracy: mastery.accuracy,
      attempts: mastery.attempts,
      status: mastery.status,
      improvement_rate: calculate_improvement_rate(mastery)
    }
  end

  def calculate_improvement_rate(mastery)
    return 0.0 if mastery.history.length < 2

    first_mastery = mastery.history.first['mastery_level'] || 0
    last_mastery = mastery.mastery_level

    ((last_mastery - first_mastery) * 100).round(2)
  end

  def concepts_needing_attention
    user_masteries_scope
      .where('mastery_level < ?', 0.5)
      .where('last_tested_at < ? OR last_tested_at IS NULL', 3.days.ago)
      .order(:mastery_level)
      .limit(5)
      .includes(:knowledge_node)
      .map { |m| concept_summary(m) }
  end

  def daily_progress_data
    (7.downto(0)).map do |days_ago|
      date = days_ago.days.ago.to_date
      masteries_tested = user_masteries_scope.where('DATE(last_tested_at) = ?', date)

      {
        date: date,
        concepts_studied: masteries_tested.count,
        accuracy: calculate_accuracy(masteries_tested),
        study_minutes: masteries_tested.sum(:total_time_minutes)
      }
    end
  end

  def weekly_progress_summary
    weeks_data = []
    4.times do |i|
      week_start = (i + 1).weeks.ago.beginning_of_week
      week_end = (i + 1).weeks.ago.end_of_week

      week_masteries = user_masteries_scope.where(last_tested_at: week_start..week_end)

      weeks_data << {
        week: "Week #{i + 1}",
        week_start: week_start,
        week_end: week_end,
        concepts_studied: week_masteries.count,
        accuracy: calculate_accuracy(week_masteries),
        mastery_gained: calculate_average_mastery(week_masteries)
      }
    end
    weeks_data.reverse
  end

  def completion_tracking_data
    total_concepts = knowledge_nodes_scope.where(level: 'concept').count

    {
      total_concepts: total_concepts,
      tested_concepts: user_masteries_scope.where('attempts > 0').count,
      mastered_concepts: user_masteries_scope.mastered_areas.count,
      completion_percentage: completion_rate
    }
  end

  def calculate_comparative_stats
    # Get all users with same study set
    all_masteries = if study_set
      UserMastery.joins(:knowledge_node)
                 .where(knowledge_nodes: { study_material_id: study_materials_ids })
    else
      UserMastery.all
    end

    {
      avg_mastery: all_masteries.average(:mastery_level).to_f.round(3),
      avg_accuracy: calculate_accuracy(all_masteries),
      total_users: all_masteries.select(:user_id).distinct.count
    }
  end

  def calculate_percentile_rank
    return 0.0 unless study_set

    user_mastery = calculate_overall_mastery

    # Get all users' average mastery for this study set
    all_user_masteries = UserMastery
      .joins(:knowledge_node)
      .where(knowledge_nodes: { study_material_id: study_materials_ids })
      .group(:user_id)
      .average(:mastery_level)
      .values

    return 0.0 if all_user_masteries.empty?

    users_below = all_user_masteries.count { |m| m < user_mastery }
    (users_below.to_f / all_user_masteries.length * 100).round(2)
  end

  def calculate_ranking_position
    return nil unless study_set

    user_mastery = calculate_overall_mastery

    rankings = UserMastery
      .joins(:knowledge_node)
      .where(knowledge_nodes: { study_material_id: study_materials_ids })
      .group(:user_id)
      .average(:mastery_level)
      .sort_by { |_user_id, mastery| -mastery }

    position = rankings.find_index { |user_id, _mastery| user_id == user.id }
    position ? position + 1 : nil
  end

  def comparison_summary(all_users_data)
    user_mastery = calculate_overall_mastery
    avg_mastery = all_users_data[:avg_mastery]

    difference = ((user_mastery - avg_mastery) * 100).round(1)

    if difference > 10
      "You're performing #{difference}% above average. Excellent work!"
    elsif difference > 0
      "You're #{difference}% above average. Keep it up!"
    elsif difference > -10
      "You're #{difference.abs}% below average. You can do it!"
    else
      "You're #{difference.abs}% below average. Consider more study time."
    end
  end

  def suggested_daily_study_time
    weak_concepts = user_masteries_scope.weak_areas.count
    learning_concepts = user_masteries_scope.learning_areas.count

    # Suggest 30 min per weak concept, 15 min per learning concept per week
    weekly_minutes = (weak_concepts * 30) + (learning_concepts * 15)
    daily_minutes = (weekly_minutes / 7.0).ceil

    [daily_minutes, 120].min # Cap at 2 hours per day
  end

  def optimal_study_times
    # This would be better with actual PerformanceSnapshot data
    # For now, return generic recommendation
    ['morning', 'afternoon']
  end

  def concepts_due_for_review
    user_masteries_scope
      .where('next_review_date <= ? OR (last_tested_at < ? AND status != ?)',
             Date.today, 7.days.ago, 'mastered')
      .order(:next_review_date, :last_tested_at)
      .limit(10)
      .includes(:knowledge_node)
      .map { |m| concept_summary(m) }
  end

  def motivational_message
    mastery = calculate_overall_mastery

    case mastery
    when 0.9..1.0
      "Outstanding! You're a master of this material!"
    when 0.8..0.9
      "Excellent progress! You're nearly there!"
    when 0.7..0.8
      "Great work! Keep up the momentum!"
    when 0.6..0.7
      "Good progress! Stay focused!"
    when 0.5..0.6
      "You're making progress. Keep studying!"
    else
      "Every expert was once a beginner. Keep going!"
    end
  end

  def performance_grade(mastery_level)
    case mastery_level
    when 0.9..1.0 then 'A+'
    when 0.85..0.9 then 'A'
    when 0.8..0.85 then 'A-'
    when 0.75..0.8 then 'B+'
    when 0.7..0.75 then 'B'
    when 0.65..0.7 then 'B-'
    when 0.6..0.65 then 'C+'
    when 0.55..0.6 then 'C'
    when 0.5..0.55 then 'C-'
    else 'D'
    end
  end
end
