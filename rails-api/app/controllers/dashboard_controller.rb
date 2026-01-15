class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    @recent_study_sets = current_user.study_sets.order(created_at: :desc).limit(5)
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
end