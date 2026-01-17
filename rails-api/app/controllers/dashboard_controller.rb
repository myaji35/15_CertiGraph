class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    # rails-best-practices: n1-includes - Eager load study_materials to prevent N+1 queries
    @recent_study_sets = current_user.study_sets
                                      .includes(:study_materials)
                                      .order(created_at: :desc)
                                      .limit(5)
    @analytics = ProgressAnalyticsService.new(current_user).overview
  end

  # GET /dashboard/statistics
  def statistics
    period = params[:period] || 'week' # day, week, month, year
    analytics_service = ProgressAnalyticsService.new(current_user)

    stats = case period
            when 'day'
              analytics_service.daily_stats
            when 'week'
              analytics_service.weekly_stats
            when 'month'
              analytics_service.monthly_stats
            when 'year'
              analytics_service.yearly_stats
            else
              analytics_service.weekly_stats
            end

    render json: {
      success: true,
      period: period,
      data: stats
    }
  end

  # GET /dashboard/progress
  def progress
    study_set_id = params[:study_set_id]
    analytics_service = ProgressAnalyticsService.new(current_user)

    progress_data = if study_set_id
                      analytics_service.study_set_progress(study_set_id)
                    else
                      analytics_service.overall_progress
                    end

    render json: {
      success: true,
      data: progress_data
    }
  end

  # GET /dashboard/learning_patterns
  def learning_patterns
    analytics_service = ProgressAnalyticsService.new(current_user)
    patterns = analytics_service.learning_patterns

    render json: {
      success: true,
      data: patterns
    }
  end

  # GET /dashboard/achievements
  def achievements
    analytics_service = ProgressAnalyticsService.new(current_user)
    achievements = analytics_service.calculate_achievements

    render json: {
      success: true,
      data: achievements
    }
  end

  # GET /dashboard/recent_activity
  def recent_activity
    limit = (params[:limit] || 10).to_i
    analytics_service = ProgressAnalyticsService.new(current_user)
    activities = analytics_service.recent_activity(limit)

    render json: {
      success: true,
      data: activities
    }
  end

  # GET /dashboard/charts
  def charts
    chart_type = params[:type]
    period = params[:period]
    chart_service = ChartDataService.new(current_user)

    chart_data = case chart_type
                 when 'line'
                   chart_service.performance_line_chart(period: period || 'month')
                 when 'bar'
                   chart_service.subject_bar_chart
                 when 'radar'
                   chart_service.capability_radar_chart
                 when 'doughnut'
                   chart_service.progress_doughnut_chart
                 when 'scatter'
                   chart_service.difficulty_accuracy_scatter
                 when 'heatmap'
                   weeks = params[:weeks]&.to_i || 12
                   chart_service.activity_heatmap_chart(weeks: weeks)
                 when 'area'
                   chart_service.cumulative_progress_area_chart
                 when 'all'
                   chart_service.all_charts
                 else
                   { error: 'Invalid chart type' }
                 end

    render json: {
      success: chart_data[:error].nil?,
      type: chart_type,
      data: chart_data
    }
  end

  # GET /dashboard/comparison
  def comparison
    target_period = params[:target_period] || 'current_month'
    comparison_period = params[:comparison_period] || 'previous_month'

    analytics_service = ProgressAnalyticsService.new(current_user)

    target_stats = get_period_stats(target_period, analytics_service)
    comparison_stats = get_period_stats(comparison_period, analytics_service)

    render json: {
      success: true,
      target: target_stats,
      comparison: comparison_stats,
      changes: calculate_changes(target_stats, comparison_stats)
    }
  end

  # GET /dashboard/predictions
  def predictions
    analytics_service = ProgressAnalyticsService.new(current_user)
    sessions = current_user.test_sessions.where(status: 'completed').order(:created_at)

    return render json: { success: false, error: 'Not enough data' } if sessions.count < 10

    # Simple linear regression for score prediction
    scores = sessions.last(30).pluck(:score)
    predicted_next_score = predict_next_score(scores)

    # Mastery completion prediction
    masteries = current_user.user_masteries
    mastery_rate = calculate_mastery_rate(masteries)
    days_to_complete = predict_days_to_mastery(masteries, mastery_rate)

    render json: {
      success: true,
      predictions: {
        next_score: predicted_next_score,
        next_score_range: [predicted_next_score - 5, predicted_next_score + 5],
        days_to_full_mastery: days_to_complete,
        estimated_completion_date: Date.current + days_to_complete.days,
        confidence: calculate_prediction_confidence(scores)
      }
    }
  end

  # GET /dashboard/realtime_status
  def realtime_status
    realtime_service = RealtimeAnalyticsService.new(current_user)

    render json: {
      success: true,
      data: {
        active_sessions: realtime_service.active_sessions_count,
        current_streak: realtime_service.current_streak,
        pending_notifications: realtime_service.pending_notifications,
        last_update: Time.current.iso8601
      }
    }
  end

  # POST /dashboard/export
  def export
    format = params[:format] || 'pdf'
    period = params[:period] || 'month'

    report_service = ReportGeneratorService.new(current_user)

    case format
    when 'pdf'
      pdf_data = report_service.generate_pdf_report(period)
      send_data pdf_data,
                filename: "dashboard_report_#{Date.current}.pdf",
                type: 'application/pdf',
                disposition: 'attachment'
    when 'csv'
      csv_data = report_service.generate_csv_report(period)
      send_data csv_data,
                filename: "dashboard_data_#{Date.current}.csv",
                type: 'text/csv',
                disposition: 'attachment'
    when 'json'
      json_data = report_service.generate_json_report(period)
      render json: {
        success: true,
        data: json_data
      }
    else
      render json: { success: false, error: 'Invalid format' }, status: :bad_request
    end
  end

  # GET /dashboard/filter
  def filter
    start_date = params[:start_date]&.to_date || 30.days.ago
    end_date = params[:end_date]&.to_date || Date.current
    study_set_ids = params[:study_set_ids]&.split(',')
    difficulty = params[:difficulty]

    # rails-best-practices: db-select-specific - Select only needed columns
    sessions = current_user.test_sessions
                           .select(:id, :score, :total_answered, :correct_answers, :started_at, :completed_at, :created_at)
                           .where(created_at: start_date..end_date)
    sessions = sessions.where(study_set_id: study_set_ids) if study_set_ids.present?

    filtered_stats = {
      total_sessions: sessions.count,
      average_score: sessions.average(:score)&.round(2) || 0,
      total_questions: sessions.sum(:total_answered),
      correct_answers: sessions.sum(:correct_answers),
      accuracy: calculate_accuracy(sessions),
      study_time_hours: calculate_total_study_time(sessions)
    }

    render json: {
      success: true,
      filters: {
        start_date: start_date,
        end_date: end_date,
        study_sets: study_set_ids,
        difficulty: difficulty
      },
      data: filtered_stats
    }
  end

  # POST /dashboard/goal
  def set_goal
    goal_type = params[:goal_type]
    target_value = params[:target_value]
    deadline = params[:deadline]&.to_date

    # Store goal (would need Goal model in production)
    render json: {
      success: true,
      goal: {
        type: goal_type,
        target: target_value,
        deadline: deadline,
        created_at: Time.current
      }
    }
  end

  # GET /dashboard/notifications
  def notifications
    realtime_service = RealtimeAnalyticsService.new(current_user)
    notifications = realtime_service.pending_notifications

    render json: {
      success: true,
      data: notifications
    }
  end

  # GET /dashboard/profile
  def profile
    @user = current_user
    @recent_study_sets = current_user.study_sets.order(created_at: :desc).limit(5)
    @analytics = ProgressAnalyticsService.new(current_user).overview
    render 'index'
  end

  private

  def get_period_stats(period, analytics_service)
    case period
    when 'current_week', 'this_week'
      analytics_service.weekly_stats
    when 'previous_week', 'last_week'
      # Would need to implement historical stats
      analytics_service.weekly_stats
    when 'current_month', 'this_month'
      analytics_service.monthly_stats
    when 'previous_month', 'last_month'
      # Would need to implement historical stats
      analytics_service.monthly_stats
    when 'current_year', 'this_year'
      analytics_service.yearly_stats
    else
      analytics_service.weekly_stats
    end
  end

  def calculate_changes(target, comparison)
    {
      sessions_change: target[:sessions_count] - comparison[:sessions_count],
      score_change: target[:average_score] - comparison[:average_score],
      questions_change: target[:questions_answered] - comparison[:questions_answered],
      time_change: target[:study_time_hours] - comparison[:study_time_hours]
    }
  end

  def predict_next_score(scores)
    return 0 if scores.empty?

    # Simple moving average
    recent_scores = scores.last(5)
    avg = recent_scores.sum / recent_scores.count.to_f

    # Add trend component
    if scores.count > 1
      trend = (scores.last - scores.first) / (scores.count - 1).to_f
      avg + trend
    else
      avg
    end.round(2)
  end

  def calculate_mastery_rate(masteries)
    return 0 if masteries.count.zero?

    mastered = masteries.where(status: 'mastered').count
    (mastered.to_f / masteries.count * 100).round(2)
  end

  def predict_days_to_mastery(masteries, current_rate)
    return Float::INFINITY if current_rate.zero?

    total = masteries.count
    mastered = masteries.where(status: 'mastered').count
    remaining = total - mastered

    # Assume linear progress
    sessions_per_day = 2 # average
    concepts_per_session = 5
    daily_progress = sessions_per_day * concepts_per_session

    (remaining / daily_progress.to_f).ceil
  end

  def calculate_prediction_confidence(scores)
    return 0 if scores.count < 5

    variance = calculate_variance(scores)
    # Lower variance = higher confidence
    [100 - (variance / 10).round(2), 0].max
  end

  def calculate_variance(numbers)
    return 0 if numbers.empty?

    mean = numbers.sum / numbers.count.to_f
    sum_squared_diff = numbers.map { |n| (n - mean)**2 }.sum
    sum_squared_diff / numbers.count
  end

  def calculate_accuracy(sessions)
    total_answered = sessions.sum(:total_answered)
    return 0 if total_answered.zero?

    correct = sessions.sum(:correct_answers)
    ((correct.to_f / total_answered) * 100).round(2)
  end

  def calculate_total_study_time(sessions)
    time_diff_sql = if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
                      'EXTRACT(EPOCH FROM (completed_at - started_at))'
                    else
                      '(julianday(completed_at) - julianday(started_at)) * 86400'
                    end

    total_seconds = sessions.where.not(started_at: nil, completed_at: nil)
                           .sum(time_diff_sql) || 0
    (total_seconds / 3600).round(2)
  end
end