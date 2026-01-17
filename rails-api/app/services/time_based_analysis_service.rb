# Service for analyzing performance based on time patterns
class TimeBasedAnalysisService
  attr_reader :user, :study_set, :date_range

  def initialize(user, study_set: nil, start_date: 30.days.ago, end_date: Date.today)
    @user = user
    @study_set = study_set
    @date_range = start_date..end_date
  end

  # Full time-based analysis
  def analyze
    {
      daily_patterns: daily_patterns,
      weekly_patterns: weekly_patterns,
      monthly_patterns: monthly_patterns,
      time_of_day_analysis: time_of_day_analysis,
      study_session_analysis: study_session_analysis,
      optimal_study_times: optimal_study_times,
      consistency_metrics: consistency_metrics,
      recommendations: time_based_recommendations
    }
  end

  # Daily performance patterns
  def daily_patterns
    days = []
    (date_range.begin.to_date..date_range.end.to_date).each do |date|
      day_data = performance_for_date(date)
      days << day_data if day_data[:study_sessions] > 0
    end

    {
      daily_data: days,
      average_daily_study_time: average_daily_study_time,
      most_productive_day: most_productive_day,
      streak_analysis: streak_analysis,
      day_of_week_patterns: day_of_week_patterns
    }
  end

  # Weekly performance patterns
  def weekly_patterns
    weeks = []
    current_date = date_range.begin.to_date.beginning_of_week
    end_date = date_range.end.to_date

    while current_date <= end_date
      week_end = [current_date.end_of_week, end_date].min
      week_data = performance_for_week(current_date, week_end)
      weeks << week_data if week_data[:total_study_time] > 0
      current_date = week_end + 1.day
    end

    {
      weekly_data: weeks,
      average_weekly_study_time: average_weekly_study_time,
      best_week: best_performing_week,
      weekly_consistency: weekly_consistency_score
    }
  end

  # Monthly performance patterns
  def monthly_patterns
    months = []
    current_date = date_range.begin.to_date.beginning_of_month
    end_date = date_range.end.to_date

    while current_date <= end_date
      month_end = [current_date.end_of_month, end_date].min
      month_data = performance_for_month(current_date, month_end)
      months << month_data if month_data[:total_study_time] > 0
      current_date = month_end + 1.day
    end

    {
      monthly_data: months,
      best_month: best_performing_month,
      monthly_growth_rate: monthly_growth_rate
    }
  end

  # Time of day analysis (morning, afternoon, evening, night)
  def time_of_day_analysis
    {
      morning: time_period_stats('morning'),
      afternoon: time_period_stats('afternoon'),
      evening: time_period_stats('evening'),
      night: time_period_stats('night'),
      best_time_of_day: best_time_of_day,
      hour_by_hour: hourly_performance
    }
  end

  # Study session analysis
  def study_session_analysis
    sessions = extract_study_sessions

    {
      total_sessions: sessions.length,
      average_session_length: average_session_length(sessions),
      longest_session: longest_session(sessions),
      shortest_session: shortest_session(sessions),
      sessions_by_duration: sessions_by_duration(sessions),
      optimal_session_length: optimal_session_length(sessions),
      session_productivity: session_productivity_analysis(sessions)
    }
  end

  # Identify optimal study times
  def optimal_study_times
    time_periods = %w[morning afternoon evening night]
    ranked_times = time_periods.map do |period|
      stats = time_period_stats(period)
      [period, stats[:accuracy], stats[:efficiency_score]]
    end.sort_by { |_period, accuracy, efficiency| -(accuracy + efficiency) }

    {
      primary_time: ranked_times[0][0],
      secondary_time: ranked_times[1][0],
      recommended_schedule: generate_recommended_schedule(ranked_times),
      peak_performance_hours: peak_performance_hours
    }
  end

  # Study consistency metrics
  def consistency_metrics
    {
      study_days_count: study_days_count,
      total_days_in_period: total_days_in_period,
      consistency_percentage: consistency_percentage,
      current_streak: current_streak,
      longest_streak: longest_streak,
      average_gap_between_sessions: average_gap_between_sessions,
      consistency_score: calculate_consistency_score
    }
  end

  # Time-based recommendations
  def time_based_recommendations
    best_time = best_time_of_day
    consistency = consistency_percentage

    recommendations = []

    # Time of day recommendations
    if best_time
      recommendations << {
        type: 'optimal_time',
        title: 'Study during your peak time',
        description: "Your #{best_time[:period]} performance is #{best_time[:accuracy].round(1)}% accurate. Schedule important topics during this time.",
        priority: 'high'
      }
    end

    # Consistency recommendations
    if consistency < 50
      recommendations << {
        type: 'consistency',
        title: 'Build a consistent study habit',
        description: "You're studying #{consistency.round(1)}% of days. Try to study at least 5 days per week.",
        priority: 'high'
      }
    end

    # Session length recommendations
    avg_session = average_daily_study_time
    if avg_session < 15
      recommendations << {
        type: 'duration',
        title: 'Increase study session length',
        description: "Your average session is #{avg_session} minutes. Aim for 30-45 minute sessions for better retention.",
        priority: 'medium'
      }
    elsif avg_session > 120
      recommendations << {
        type: 'duration',
        title: 'Break up long study sessions',
        description: "Your sessions average #{avg_session} minutes. Consider breaking into 45-60 minute blocks with breaks.",
        priority: 'medium'
      }
    end

    # Streak recommendations
    if current_streak[:days] > 7
      recommendations << {
        type: 'motivation',
        title: 'Amazing streak!',
        description: "You've studied #{current_streak[:days]} days in a row! Keep it up!",
        priority: 'low'
      }
    end

    recommendations
  end

  private

  def performance_for_date(date)
    masteries = user_masteries_scope
      .where('DATE(last_tested_at) = ?', date)

    {
      date: date,
      day_of_week: date.strftime('%A'),
      study_sessions: masteries.count,
      total_study_time: masteries.sum(:total_time_minutes),
      accuracy: calculate_accuracy(masteries),
      mastery_gained: masteries.sum(:mastery_level) / [masteries.count, 1].max.to_f,
      concepts_studied: masteries.count
    }
  end

  def performance_for_week(start_date, end_date)
    masteries = user_masteries_scope
      .where(last_tested_at: start_date.beginning_of_day..end_date.end_of_day)

    {
      week_start: start_date,
      week_end: end_date,
      week_number: start_date.strftime('%U').to_i,
      total_study_time: masteries.sum(:total_time_minutes),
      study_days: masteries.select('DISTINCT DATE(last_tested_at)').count,
      accuracy: calculate_accuracy(masteries),
      concepts_mastered: masteries.where('mastery_level >= ?', 0.8).count,
      total_attempts: masteries.sum(:attempts)
    }
  end

  def performance_for_month(start_date, end_date)
    masteries = user_masteries_scope
      .where(last_tested_at: start_date.beginning_of_day..end_date.end_of_day)

    {
      month: start_date.strftime('%B %Y'),
      month_start: start_date,
      month_end: end_date,
      total_study_time: masteries.sum(:total_time_minutes),
      study_days: masteries.select('DISTINCT DATE(last_tested_at)').count,
      accuracy: calculate_accuracy(masteries),
      mastery_improvement: calculate_mastery_improvement(masteries),
      concepts_mastered: masteries.where('mastery_level >= ?', 0.8).count
    }
  end

  def time_period_stats(period)
    # Define time ranges
    ranges = {
      'morning' => 6..11,
      'afternoon' => 12..17,
      'evening' => 18..23,
      'night' => 0..5
    }

    hour_range = ranges[period]
    return {} unless hour_range

    # Get masteries where history has entries in this time period
    masteries = user_masteries_scope.select do |mastery|
      next false unless mastery.history.present?

      mastery.history.any? do |entry|
        hour = Time.parse(entry['timestamp']).hour
        hour_range.include?(hour)
      end
    end

    # Calculate stats from matching history entries
    period_entries = []
    masteries.each do |mastery|
      mastery.history.each do |entry|
        hour = Time.parse(entry['timestamp']).hour
        period_entries << entry if hour_range.include?(hour)
      end
    end

    return default_period_stats if period_entries.empty?

    correct_count = period_entries.count { |e| e['correct'] }
    total_time = period_entries.sum { |e| e['time_minutes'] || 0 }

    {
      period: period,
      total_attempts: period_entries.length,
      correct_attempts: correct_count,
      accuracy: (correct_count.to_f / period_entries.length * 100).round(2),
      total_study_time: total_time,
      avg_session_time: (total_time.to_f / period_entries.length).round(1),
      efficiency_score: calculate_efficiency_score(correct_count, total_time)
    }
  end

  def default_period_stats
    {
      period: '',
      total_attempts: 0,
      correct_attempts: 0,
      accuracy: 0.0,
      total_study_time: 0,
      avg_session_time: 0.0,
      efficiency_score: 0.0
    }
  end

  def best_time_of_day
    periods = %w[morning afternoon evening night]
    best = periods.map do |period|
      stats = time_period_stats(period)
      next nil if stats[:total_attempts].zero?

      {
        period: period,
        accuracy: stats[:accuracy],
        efficiency: stats[:efficiency_score],
        total_study_time: stats[:total_study_time]
      }
    end.compact

    return nil if best.empty?

    best.max_by { |p| p[:accuracy] + p[:efficiency] }
  end

  def hourly_performance
    (0..23).map do |hour|
      hour_entries = []

      user_masteries_scope.each do |mastery|
        next unless mastery.history.present?

        mastery.history.each do |entry|
          entry_hour = Time.parse(entry['timestamp']).hour
          hour_entries << entry if entry_hour == hour
        end
      end

      correct = hour_entries.count { |e| e['correct'] }
      accuracy = hour_entries.empty? ? 0.0 : (correct.to_f / hour_entries.length * 100).round(2)

      {
        hour: hour,
        hour_label: "#{hour}:00",
        attempts: hour_entries.length,
        accuracy: accuracy
      }
    end
  end

  def extract_study_sessions
    # Group consecutive study activities into sessions (gap > 30 min = new session)
    all_activities = []

    user_masteries_scope.each do |mastery|
      next unless mastery.history.present?

      mastery.history.each do |entry|
        all_activities << {
          timestamp: Time.parse(entry['timestamp']),
          duration: entry['time_minutes'] || 5,
          correct: entry['correct']
        }
      end
    end

    all_activities.sort_by! { |a| a[:timestamp] }

    sessions = []
    current_session = nil

    all_activities.each do |activity|
      if current_session.nil? || (activity[:timestamp] - current_session[:end_time]) > 30.minutes
        # Start new session
        sessions << current_session if current_session
        current_session = {
          start_time: activity[:timestamp],
          end_time: activity[:timestamp] + activity[:duration].minutes,
          duration: activity[:duration],
          attempts: 1,
          correct: activity[:correct] ? 1 : 0
        }
      else
        # Continue current session
        current_session[:end_time] = activity[:timestamp] + activity[:duration].minutes
        current_session[:duration] += activity[:duration]
        current_session[:attempts] += 1
        current_session[:correct] += 1 if activity[:correct]
      end
    end

    sessions << current_session if current_session
    sessions
  end

  def average_session_length(sessions)
    return 0 if sessions.empty?
    (sessions.sum { |s| s[:duration] } / sessions.length.to_f).round(1)
  end

  def longest_session(sessions)
    return nil if sessions.empty?
    sessions.max_by { |s| s[:duration] }
  end

  def shortest_session(sessions)
    return nil if sessions.empty?
    sessions.min_by { |s| s[:duration] }
  end

  def sessions_by_duration(sessions)
    {
      short: sessions.count { |s| s[:duration] < 15 },
      medium: sessions.count { |s| s[:duration] >= 15 && s[:duration] < 45 },
      long: sessions.count { |s| s[:duration] >= 45 && s[:duration] < 90 },
      very_long: sessions.count { |s| s[:duration] >= 90 }
    }
  end

  def optimal_session_length(sessions)
    return 30 if sessions.empty?

    # Find session length with best accuracy
    duration_groups = sessions.group_by do |s|
      case s[:duration]
      when 0..15 then '0-15'
      when 16..30 then '16-30'
      when 31..45 then '31-45'
      when 46..60 then '46-60'
      else '60+'
      end
    end

    best_group = duration_groups.max_by do |_group, group_sessions|
      correct = group_sessions.sum { |s| s[:correct] }
      total = group_sessions.sum { |s| s[:attempts] }
      total.zero? ? 0 : (correct.to_f / total)
    end

    best_group ? best_group[0] : '31-45'
  end

  def session_productivity_analysis(sessions)
    return {} if sessions.empty?

    {
      most_productive_sessions: sessions
        .sort_by { |s| s[:correct].to_f / s[:attempts] }
        .reverse
        .first(5),
      least_productive_sessions: sessions
        .sort_by { |s| s[:correct].to_f / s[:attempts] }
        .first(5),
      productivity_trend: calculate_productivity_trend(sessions)
    }
  end

  def calculate_productivity_trend(sessions)
    return 'stable' if sessions.length < 4

    recent = sessions.last(sessions.length / 2)
    older = sessions.first(sessions.length / 2)

    recent_productivity = recent.sum { |s| s[:correct].to_f / s[:attempts] } / recent.length
    older_productivity = older.sum { |s| s[:correct].to_f / s[:attempts] } / older.length

    if recent_productivity > older_productivity * 1.1
      'improving'
    elsif recent_productivity < older_productivity * 0.9
      'declining'
    else
      'stable'
    end
  end

  def peak_performance_hours
    hourly = hourly_performance
    hourly.select { |h| h[:attempts] > 0 }
          .sort_by { |h| -h[:accuracy] }
          .first(3)
          .map { |h| h[:hour_label] }
  end

  def generate_recommended_schedule(ranked_times)
    {
      primary_slot: "#{ranked_times[0][0]} (best performance)",
      secondary_slot: "#{ranked_times[1][0]} (good performance)",
      suggested_routine: "Study difficult topics during #{ranked_times[0][0]}, " \
                        "review during #{ranked_times[1][0]}"
    }
  end

  def study_days_count
    user_masteries_scope
      .where('last_tested_at >= ? AND last_tested_at <= ?',
             date_range.begin.beginning_of_day, date_range.end.end_of_day)
      .select('DISTINCT DATE(last_tested_at)')
      .count
  end

  def total_days_in_period
    (date_range.end.to_date - date_range.begin.to_date).to_i + 1
  end

  def consistency_percentage
    return 0.0 if total_days_in_period.zero?
    (study_days_count.to_f / total_days_in_period * 100).round(2)
  end

  def current_streak
    dates = user_masteries_scope
      .where('last_tested_at IS NOT NULL')
      .select('DISTINCT DATE(last_tested_at) as study_date')
      .order('study_date DESC')
      .pluck(:study_date)

    return { days: 0, start_date: nil, end_date: nil } if dates.empty?

    streak_days = 0
    current_date = Date.today

    dates.each do |date|
      break if date < current_date - 1.day
      streak_days += 1 if date == current_date
      current_date = date - 1.day
    end

    {
      days: streak_days,
      start_date: dates.first - (streak_days - 1).days,
      end_date: dates.first
    }
  end

  def longest_streak
    dates = user_masteries_scope
      .where('last_tested_at IS NOT NULL')
      .select('DISTINCT DATE(last_tested_at) as study_date')
      .order('study_date ASC')
      .pluck(:study_date)

    return { days: 0 } if dates.empty?

    max_streak = 1
    current_streak = 1

    dates.each_cons(2) do |date1, date2|
      if date2 == date1 + 1.day
        current_streak += 1
        max_streak = [max_streak, current_streak].max
      else
        current_streak = 1
      end
    end

    { days: max_streak }
  end

  def average_gap_between_sessions
    dates = user_masteries_scope
      .where('last_tested_at IS NOT NULL')
      .select('DISTINCT DATE(last_tested_at) as study_date')
      .order('study_date ASC')
      .pluck(:study_date)

    return 0 if dates.length < 2

    gaps = dates.each_cons(2).map { |d1, d2| (d2 - d1).to_i }
    (gaps.sum.to_f / gaps.length).round(1)
  end

  def calculate_consistency_score
    # Score based on multiple factors
    consistency_pct = consistency_percentage
    avg_gap = average_gap_between_sessions
    current = current_streak[:days]

    # Base score from consistency percentage
    score = consistency_pct

    # Bonus for current streak
    score += [current * 2, 20].min

    # Penalty for large gaps
    score -= [avg_gap * 2, 20].min if avg_gap > 2

    [score, 100].min.round(1)
  end

  def average_daily_study_time
    total_minutes = user_masteries_scope.sum(:total_time_minutes)
    return 0 if study_days_count.zero?
    (total_minutes.to_f / study_days_count).round(1)
  end

  def average_weekly_study_time
    total_minutes = user_masteries_scope.sum(:total_time_minutes)
    weeks = (total_days_in_period / 7.0).ceil
    return 0 if weeks.zero?
    (total_minutes.to_f / weeks).round(1)
  end

  def most_productive_day
    daily_data = (date_range.begin.to_date..date_range.end.to_date).map do |date|
      performance_for_date(date)
    end.reject { |d| d[:study_sessions].zero? }

    return nil if daily_data.empty?

    daily_data.max_by { |d| d[:accuracy] + (d[:mastery_gained] * 10) }
  end

  def day_of_week_patterns
    %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday].map do |dow|
      dates = (date_range.begin.to_date..date_range.end.to_date).select { |d| d.strftime('%A') == dow }

      dow_data = dates.map { |date| performance_for_date(date) }
                      .reject { |d| d[:study_sessions].zero? }

      next nil if dow_data.empty?

      {
        day: dow,
        avg_study_time: (dow_data.sum { |d| d[:total_study_time] } / dow_data.length.to_f).round(1),
        avg_accuracy: (dow_data.sum { |d| d[:accuracy] } / dow_data.length.to_f).round(2),
        study_frequency: dow_data.length
      }
    end.compact
  end

  def best_performing_week
    weeks = []
    current_date = date_range.begin.to_date.beginning_of_week

    while current_date <= date_range.end.to_date
      week_end = [current_date.end_of_week, date_range.end.to_date].min
      weeks << performance_for_week(current_date, week_end)
      current_date = week_end + 1.day
    end

    weeks.max_by { |w| w[:accuracy] + (w[:concepts_mastered] * 2) }
  end

  def best_performing_month
    months = []
    current_date = date_range.begin.to_date.beginning_of_month

    while current_date <= date_range.end.to_date
      month_end = [current_date.end_of_month, date_range.end.to_date].min
      months << performance_for_month(current_date, month_end)
      current_date = month_end + 1.day
    end

    months.max_by { |m| m[:accuracy] + (m[:concepts_mastered] * 2) }
  end

  def weekly_consistency_score
    weeks = []
    current_date = date_range.begin.to_date.beginning_of_week

    while current_date <= date_range.end.to_date
      week_end = [current_date.end_of_week, date_range.end.to_date].min
      week_data = performance_for_week(current_date, week_end)
      weeks << week_data[:study_days] if week_data[:total_study_time] > 0
      current_date = week_end + 1.day
    end

    return 0.0 if weeks.empty?

    # Consistency is measured by variance in study days per week
    avg = weeks.sum.to_f / weeks.length
    variance = weeks.sum { |w| (w - avg)**2 } / weeks.length.to_f
    std_dev = Math.sqrt(variance)

    # Lower std_dev = higher consistency
    # Score from 0-100, where 0 variance = 100 score
    consistency = 100 - (std_dev * 20)
    [consistency, 0].max.round(1)
  end

  def monthly_growth_rate
    months = []
    current_date = date_range.begin.to_date.beginning_of_month

    while current_date <= date_range.end.to_date
      month_end = [current_date.end_of_month, date_range.end.to_date].min
      months << performance_for_month(current_date, month_end)
      current_date = month_end + 1.day
    end

    return 0.0 if months.length < 2

    first_month = months.first[:concepts_mastered] || 0
    last_month = months.last[:concepts_mastered] || 0

    return 0.0 if first_month.zero?

    ((last_month - first_month).to_f / first_month * 100).round(2)
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

  def calculate_accuracy(masteries)
    total_attempts = masteries.sum(:attempts)
    return 0.0 if total_attempts.zero?

    (masteries.sum(:correct_attempts).to_f / total_attempts * 100).round(2)
  end

  def calculate_mastery_improvement(masteries)
    return 0.0 if masteries.empty?

    improvements = masteries.select do |m|
      m.history.length >= 2
    end.map do |m|
      m.mastery_level - m.history.first['mastery_level'].to_f
    end

    return 0.0 if improvements.empty?

    (improvements.sum / improvements.length.to_f).round(3)
  end

  def calculate_efficiency_score(correct_count, total_time)
    return 0.0 if total_time.zero?

    # Correct answers per minute * 60 (to get per hour)
    (correct_count.to_f / total_time * 60).round(2)
  end
end
