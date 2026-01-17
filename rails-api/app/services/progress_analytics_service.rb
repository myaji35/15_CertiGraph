# app/services/progress_analytics_service.rb
class ProgressAnalyticsService
  def initialize(user)
    @user = user
  end

  # Helper method for database-agnostic time difference calculation
  def time_diff_sql
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      'EXTRACT(EPOCH FROM (completed_at - started_at))'
    else
      '(julianday(completed_at) - julianday(started_at)) * 86400'
    end
  end

  def hour_extract_sql(column)
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      "EXTRACT(HOUR FROM #{column})"
    else
      "CAST(strftime('%H', #{column}) AS INTEGER)"
    end
  end

  # Overview statistics for dashboard
  def overview
    {
      total_study_sets: @user.study_sets.count,
      total_test_sessions: @user.test_sessions.count,
      completed_tests: @user.test_sessions.where(status: 'completed').count,
      average_score: average_score,
      total_study_time: total_study_time,
      mastery_overview: mastery_overview,
      streak_days: calculate_streak,
      recent_improvement: recent_improvement
    }
  end

  # Daily statistics
  def daily_stats
    today = Time.current.beginning_of_day
    sessions_today = @user.test_sessions.where('created_at >= ?', today)

    {
      date: today.to_date,
      sessions_count: sessions_today.count,
      questions_answered: sessions_today.sum(:total_answered),
      correct_answers: sessions_today.sum(:correct_answers),
      study_time_minutes: sessions_today.sum("#{time_diff_sql}/60"),
      average_score: sessions_today.average(:score)&.round(2) || 0,
      hourly_breakdown: hourly_activity_breakdown(today)
    }
  end

  # Weekly statistics
  def weekly_stats
    week_start = Time.current.beginning_of_week
    sessions_this_week = @user.test_sessions.where('created_at >= ?', week_start)

    {
      week_start: week_start.to_date,
      week_end: Time.current.end_of_week.to_date,
      sessions_count: sessions_this_week.count,
      questions_answered: sessions_this_week.sum(:total_answered),
      correct_answers: sessions_this_week.sum(:correct_answers),
      study_time_hours: (sessions_this_week.sum("#{time_diff_sql}/3600") || 0).round(2),
      average_score: sessions_this_week.average(:score)&.round(2) || 0,
      daily_breakdown: daily_breakdown(week_start, Time.current.end_of_week),
      improvement_rate: calculate_improvement_rate(week_start)
    }
  end

  # Monthly statistics
  def monthly_stats
    month_start = Time.current.beginning_of_month
    sessions_this_month = @user.test_sessions.where('created_at >= ?', month_start)

    {
      month: month_start.strftime('%Y-%m'),
      sessions_count: sessions_this_month.count,
      questions_answered: sessions_this_month.sum(:total_answered),
      correct_answers: sessions_this_month.sum(:correct_answers),
      study_time_hours: (sessions_this_month.sum("#{time_diff_sql}/3600") || 0).round(2),
      average_score: sessions_this_month.average(:score)&.round(2) || 0,
      weekly_breakdown: weekly_breakdown(month_start, Time.current.end_of_month),
      best_day: best_performance_day(month_start),
      mastery_progress: monthly_mastery_progress(month_start)
    }
  end

  # Yearly statistics
  def yearly_stats
    year_start = Time.current.beginning_of_year
    sessions_this_year = @user.test_sessions.where('created_at >= ?', year_start)

    {
      year: year_start.year,
      sessions_count: sessions_this_year.count,
      questions_answered: sessions_this_year.sum(:total_answered),
      correct_answers: sessions_this_year.sum(:correct_answers),
      study_time_hours: (sessions_this_year.sum("#{time_diff_sql}/3600") || 0).round(2),
      average_score: sessions_this_year.average(:score)&.round(2) || 0,
      monthly_breakdown: monthly_breakdown(year_start, Time.current),
      total_improvement: total_improvement_rate(year_start)
    }
  end

  # Overall progress across all study sets
  def overall_progress
    {
      total_concepts: total_concepts_count,
      mastered_concepts: mastered_concepts_count,
      weak_concepts: weak_concepts_count,
      untested_concepts: untested_concepts_count,
      mastery_percentage: mastery_percentage,
      progress_by_study_set: progress_by_study_set
    }
  end

  # Progress for a specific study set
  def study_set_progress(study_set_id)
    study_set = @user.study_sets.find(study_set_id)
    sessions = @user.test_sessions.where(study_set: study_set)
    masteries = @user.user_masteries.joins(:knowledge_node)
                     .where(knowledge_nodes: { study_material_id: study_set.study_materials.pluck(:id) })

    {
      study_set_id: study_set.id,
      study_set_name: study_set.title,
      total_sessions: sessions.count,
      completed_sessions: sessions.where(status: 'completed').count,
      average_score: sessions.average(:score)&.round(2) || 0,
      total_concepts: masteries.count,
      mastered_concepts: masteries.where(status: 'mastered').count,
      weak_concepts: masteries.where(status: 'weak').count,
      progress_over_time: progress_timeline(study_set),
      recent_sessions: sessions.order(created_at: :desc).limit(5).as_json(only: [:id, :score, :status, :created_at])
    }
  end

  # Learning patterns analysis
  def learning_patterns
    {
      preferred_study_times: preferred_study_times,
      average_session_duration: average_session_duration,
      questions_per_session: average_questions_per_session,
      accuracy_trends: accuracy_trends,
      difficulty_distribution: difficulty_distribution,
      concept_mastery_rate: concept_mastery_rate,
      weak_areas: identify_weak_areas
    }
  end

  # Calculate achievements
  def calculate_achievements
    {
      total_points: calculate_total_points,
      level: calculate_level,
      badges: earned_badges,
      milestones: reached_milestones,
      next_milestone: next_milestone_info
    }
  end

  # Recent activity
  def recent_activity(limit = 10)
    activities = []

    # Test sessions
    @user.test_sessions.order(created_at: :desc).limit(limit).each do |session|
      activities << {
        type: 'test_session',
        action: session.status == 'completed' ? 'completed' : 'started',
        timestamp: session.created_at,
        details: {
          study_set: session.study_set.title,
          score: session.score,
          questions: session.total_answered
        }
      }
    end

    # Mastery updates
    @user.user_masteries.order(updated_at: :desc).limit(limit).each do |mastery|
      activities << {
        type: 'mastery_update',
        action: 'improved',
        timestamp: mastery.updated_at,
        details: {
          concept: mastery.knowledge_node.name,
          level: mastery.mastery_level,
          status: mastery.status
        }
      }
    end

    activities.sort_by { |a| a[:timestamp] }.reverse.take(limit)
  end

  private

  def average_score
    @user.test_sessions.where(status: 'completed').average(:score)&.round(2) || 0
  end

  def total_study_time
    total_seconds = @user.test_sessions
                        .where.not(started_at: nil, completed_at: nil)
                        .sum(time_diff_sql) || 0
    (total_seconds / 3600).round(2) # Convert to hours
  end

  def mastery_overview
    masteries = @user.user_masteries
    {
      mastered: masteries.where(status: 'mastered').count,
      learning: masteries.where(status: 'learning').count,
      weak: masteries.where(status: 'weak').count,
      untested: masteries.where(status: 'untested').count
    }
  end

  def calculate_streak
    dates = @user.test_sessions.where(status: 'completed')
                 .order(created_at: :desc)
                 .pluck(:created_at)
                 .map { |d| d.to_date }
                 .uniq

    return 0 if dates.empty?

    streak = 1
    dates.each_cons(2) do |current, previous|
      break unless (previous - current).to_i == 1
      streak += 1
    end
    streak
  end

  def recent_improvement
    recent_sessions = @user.test_sessions.where(status: 'completed').order(created_at: :desc).limit(10)
    return 0 if recent_sessions.count < 2

    recent_avg = recent_sessions.limit(5).average(:score) || 0
    older_avg = recent_sessions.offset(5).limit(5).average(:score) || 0

    return 0 if older_avg.zero?
    ((recent_avg - older_avg) / older_avg * 100).round(2)
  end

  def hourly_activity_breakdown(start_date)
    sessions = @user.test_sessions.where('created_at >= ?', start_date)
    breakdown = Hash.new(0)

    sessions.each do |session|
      hour = session.created_at.hour
      breakdown[hour] += 1
    end

    (0..23).map { |hour| { hour: hour, count: breakdown[hour] } }
  end

  def daily_breakdown(start_date, end_date)
    sessions = @user.test_sessions.where(created_at: start_date..end_date)
    dates = (start_date.to_date..end_date.to_date).to_a

    dates.map do |date|
      day_sessions = sessions.select { |s| s.created_at.to_date == date }
      {
        date: date,
        sessions_count: day_sessions.count,
        average_score: day_sessions.map(&:score).compact.sum / [day_sessions.count, 1].max
      }
    end
  end

  def weekly_breakdown(start_date, end_date)
    sessions = @user.test_sessions.where(created_at: start_date..end_date)
    weeks = []
    current = start_date

    while current <= end_date
      week_end = [current.end_of_week, end_date].min
      week_sessions = sessions.select { |s| s.created_at >= current && s.created_at <= week_end }

      weeks << {
        week_start: current.to_date,
        week_end: week_end.to_date,
        sessions_count: week_sessions.count,
        average_score: week_sessions.map(&:score).compact.sum / [week_sessions.count, 1].max
      }

      current = week_end + 1.day
    end

    weeks
  end

  def monthly_breakdown(start_date, end_date)
    sessions = @user.test_sessions.where(created_at: start_date..end_date)
    months = []
    current = start_date

    while current <= end_date
      month_end = [current.end_of_month, end_date].min
      month_sessions = sessions.select { |s| s.created_at >= current && s.created_at <= month_end }

      months << {
        month: current.strftime('%Y-%m'),
        sessions_count: month_sessions.count,
        average_score: month_sessions.map(&:score).compact.sum / [month_sessions.count, 1].max
      }

      current = month_end + 1.day
    end

    months
  end

  def calculate_improvement_rate(start_date)
    sessions = @user.test_sessions.where('created_at >= ?', start_date).order(:created_at)
    return 0 if sessions.count < 2

    first_half = sessions.limit(sessions.count / 2).average(:score) || 0
    second_half = sessions.offset(sessions.count / 2).average(:score) || 0

    return 0 if first_half.zero?
    ((second_half - first_half) / first_half * 100).round(2)
  end

  def best_performance_day(start_date)
    sessions = @user.test_sessions.where('created_at >= ?', start_date).where(status: 'completed')
    return nil if sessions.empty?

    sessions.group('DATE(created_at)').average(:score).max_by { |_, score| score }&.first
  end

  def monthly_mastery_progress(start_date)
    start_masteries = @user.user_masteries.where('created_at < ?', start_date).where(status: 'mastered').count
    end_masteries = @user.user_masteries.where(status: 'mastered').count

    {
      start_count: start_masteries,
      end_count: end_masteries,
      new_masteries: end_masteries - start_masteries
    }
  end

  def total_improvement_rate(start_date)
    sessions = @user.test_sessions.where('created_at >= ?', start_date).order(:created_at)
    return 0 if sessions.count < 10

    first_ten = sessions.limit(10).average(:score) || 0
    last_ten = sessions.order(created_at: :desc).limit(10).average(:score) || 0

    return 0 if first_ten.zero?
    ((last_ten - first_ten) / first_ten * 100).round(2)
  end

  def total_concepts_count
    @user.user_masteries.count
  end

  def mastered_concepts_count
    @user.user_masteries.where(status: 'mastered').count
  end

  def weak_concepts_count
    @user.user_masteries.where(status: 'weak').count
  end

  def untested_concepts_count
    @user.user_masteries.where(status: 'untested').count
  end

  def mastery_percentage
    total = total_concepts_count
    return 0 if total.zero?
    (mastered_concepts_count.to_f / total * 100).round(2)
  end

  def progress_by_study_set
    @user.study_sets.map do |study_set|
      masteries = @user.user_masteries.joins(:knowledge_node)
                       .where(knowledge_nodes: { study_material_id: study_set.study_materials.pluck(:id) })

      {
        study_set_id: study_set.id,
        title: study_set.title,
        total_concepts: masteries.count,
        mastered: masteries.where(status: 'mastered').count,
        progress_percentage: masteries.count.zero? ? 0 : (masteries.where(status: 'mastered').count.to_f / masteries.count * 100).round(2)
      }
    end
  end

  def progress_timeline(study_set)
    sessions = @user.test_sessions.where(study_set: study_set).order(:created_at)
    sessions.map do |session|
      {
        date: session.created_at.to_date,
        score: session.score,
        questions: session.total_answered
      }
    end
  end

  def preferred_study_times
    sessions = @user.test_sessions.where.not(started_at: nil)
    hour_counts = sessions.group(hour_extract_sql('started_at')).count

    hour_counts.map { |hour, count| { hour: hour.to_i, count: count } }
               .sort_by { |h| -h[:count] }
               .take(3)
  end

  def average_session_duration
    total_seconds = @user.test_sessions
                        .where.not(started_at: nil, completed_at: nil)
                        .average(time_diff_sql) || 0
    (total_seconds / 60).round(2) # Convert to minutes
  end

  def average_questions_per_session
    @user.test_sessions.average(:total_answered)&.round(2) || 0
  end

  def accuracy_trends
    sessions = @user.test_sessions.where(status: 'completed').order(:created_at).last(20)
    sessions.map do |session|
      {
        date: session.created_at.to_date,
        accuracy: session.total_answered.zero? ? 0 : (session.correct_answers.to_f / session.total_answered * 100).round(2)
      }
    end
  end

  def difficulty_distribution
    # This would need a difficulty field in questions
    # Placeholder implementation
    {
      easy: 0,
      medium: 0,
      hard: 0
    }
  end

  def concept_mastery_rate
    masteries = @user.user_masteries
    total = masteries.count
    return 0 if total.zero?

    {
      mastery_rate: (masteries.where(status: 'mastered').count.to_f / total * 100).round(2),
      average_attempts: masteries.average(:attempts)&.round(2) || 0
    }
  end

  def identify_weak_areas
    @user.user_masteries
        .where(status: 'weak')
        .joins(:knowledge_node)
        .order(mastery_level: :asc)
        .limit(5)
        .map do |mastery|
          {
            concept: mastery.knowledge_node.name,
            mastery_level: mastery.mastery_level,
            attempts: mastery.attempts
          }
        end
  end

  def calculate_total_points
    # Points calculation based on various achievements
    test_points = @user.test_sessions.where(status: 'completed').sum(:score) || 0
    mastery_points = @user.user_masteries.where(status: 'mastered').count * 10
    streak_points = calculate_streak * 5

    test_points + mastery_points + streak_points
  end

  def calculate_level
    points = calculate_total_points
    (points / 100).to_i + 1
  end

  def earned_badges
    badges = []

    # First test badge
    badges << { name: 'First Steps', description: 'Completed first test' } if @user.test_sessions.any?

    # Mastery badges
    mastered_count = mastered_concepts_count
    badges << { name: 'Knowledge Seeker', description: 'Mastered 10 concepts' } if mastered_count >= 10
    badges << { name: 'Expert', description: 'Mastered 50 concepts' } if mastered_count >= 50
    badges << { name: 'Master', description: 'Mastered 100 concepts' } if mastered_count >= 100

    # Streak badges
    streak = calculate_streak
    badges << { name: 'Consistent', description: '7-day streak' } if streak >= 7
    badges << { name: 'Dedicated', description: '30-day streak' } if streak >= 30

    badges
  end

  def reached_milestones
    milestones = []
    sessions_count = @user.test_sessions.count

    [10, 50, 100, 500].each do |count|
      milestones << { description: "#{count} test sessions", reached: sessions_count >= count } if sessions_count >= count
    end

    milestones
  end

  def next_milestone_info
    sessions_count = @user.test_sessions.count
    next_milestone = [10, 50, 100, 500, 1000].find { |m| m > sessions_count }

    return nil unless next_milestone

    {
      target: next_milestone,
      current: sessions_count,
      remaining: next_milestone - sessions_count,
      progress_percentage: (sessions_count.to_f / next_milestone * 100).round(2)
    }
  end
end
