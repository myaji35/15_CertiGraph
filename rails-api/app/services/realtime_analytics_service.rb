# app/services/realtime_analytics_service.rb
class RealtimeAnalyticsService
  def initialize(user)
    @user = user
    @analytics = ProgressAnalyticsService.new(user)
    @chart_service = ChartDataService.new(user)
  end

  # Broadcast current statistics
  def broadcast_statistics
    stats = current_statistics
    ActionCable.server.broadcast(
      "dashboard_#{@user.id}",
      {
        type: 'statistics_update',
        data: stats,
        timestamp: Time.current.iso8601
      }
    )
  end

  # Broadcast after test session completion
  def broadcast_session_completion(test_session)
    data = {
      type: 'session_completed',
      session: {
        id: test_session.id,
        score: test_session.score,
        total_answered: test_session.total_answered,
        correct_answers: test_session.correct_answers,
        accuracy: calculate_accuracy(test_session),
        duration: calculate_duration(test_session),
        created_at: test_session.created_at
      },
      updated_stats: current_statistics,
      timestamp: Time.current.iso8601
    }

    ActionCable.server.broadcast("dashboard_#{@user.id}", data)
  end

  # Broadcast mastery update
  def broadcast_mastery_update(user_mastery)
    data = {
      type: 'mastery_updated',
      mastery: {
        concept: user_mastery.knowledge_node.name,
        old_status: user_mastery.status_was,
        new_status: user_mastery.status,
        old_level: user_mastery.mastery_level_was,
        new_level: user_mastery.mastery_level,
        attempts: user_mastery.attempts
      },
      mastery_overview: @analytics.overview[:mastery_overview],
      timestamp: Time.current.iso8601
    }

    ActionCable.server.broadcast("dashboard_#{@user.id}", data)
  end

  # Broadcast achievement unlocked
  def broadcast_achievement(achievement)
    data = {
      type: 'achievement_unlocked',
      achievement: achievement,
      all_achievements: @analytics.calculate_achievements,
      timestamp: Time.current.iso8601
    }

    ActionCable.server.broadcast("dashboard_#{@user.id}", data)
  end

  # Broadcast rank change
  def broadcast_rank_change(old_rank, new_rank)
    data = {
      type: 'rank_changed',
      old_rank: old_rank,
      new_rank: new_rank,
      change: new_rank - old_rank,
      timestamp: Time.current.iso8601
    }

    ActionCable.server.broadcast("dashboard_#{@user.id}", data)
  end

  # Broadcast chart update
  def broadcast_chart_update(chart_type)
    chart_data = case chart_type
                 when 'line'
                   @chart_service.performance_line_chart
                 when 'bar'
                   @chart_service.subject_bar_chart
                 when 'radar'
                   @chart_service.capability_radar_chart
                 when 'doughnut'
                   @chart_service.progress_doughnut_chart
                 when 'scatter'
                   @chart_service.difficulty_accuracy_scatter
                 when 'heatmap'
                   @chart_service.activity_heatmap_chart
                 when 'area'
                   @chart_service.cumulative_progress_area_chart
                 else
                   nil
                 end

    return unless chart_data

    data = {
      type: 'chart_update',
      chart_type: chart_type,
      chart_data: chart_data,
      timestamp: Time.current.iso8601
    }

    ActionCable.server.broadcast("dashboard_#{@user.id}", data)
  end

  # Broadcast all updates (full refresh)
  def broadcast_full_update
    data = {
      type: 'full_update',
      statistics: current_statistics,
      charts: @chart_service.all_charts,
      achievements: @analytics.calculate_achievements,
      recent_activity: @analytics.recent_activity(10),
      timestamp: Time.current.iso8601
    }

    ActionCable.server.broadcast("dashboard_#{@user.id}", data)
  end

  # Get live session progress
  def live_session_progress(test_session)
    {
      session_id: test_session.id,
      status: test_session.status,
      progress_percentage: calculate_progress_percentage(test_session),
      questions_answered: test_session.total_answered,
      questions_remaining: test_session.total_questions - test_session.total_answered,
      current_score: test_session.score,
      elapsed_time: calculate_duration(test_session),
      estimated_completion: estimate_completion_time(test_session),
      timestamp: Time.current.iso8601
    }
  end

  # Stream live session updates
  def stream_session_progress(test_session)
    progress = live_session_progress(test_session)

    ActionCable.server.broadcast(
      "dashboard_#{@user.id}",
      {
        type: 'session_progress',
        data: progress
      }
    )
  end

  # Get current active sessions count
  def active_sessions_count
    @user.test_sessions.where(status: 'in_progress').count
  end

  # Calculate study streak
  def current_streak
    @analytics.send(:calculate_streak)
  end

  # Get real-time notifications
  def pending_notifications
    {
      upcoming_exams: upcoming_exams_count,
      weak_concepts: weak_concepts_count,
      recommendations: recommendations_count,
      achievements: unread_achievements_count
    }
  end

  # Broadcast notification
  def broadcast_notification(notification)
    data = {
      type: 'notification',
      notification: notification,
      pending_counts: pending_notifications,
      timestamp: Time.current.iso8601
    }

    ActionCable.server.broadcast("dashboard_#{@user.id}", data)
  end

  private

  def current_statistics
    overview = @analytics.overview

    {
      overview: overview,
      progress: @analytics.overall_progress,
      learning_patterns: @analytics.learning_patterns,
      recent_improvement: overview[:recent_improvement],
      streak_days: overview[:streak_days],
      active_sessions: active_sessions_count
    }
  end

  def calculate_accuracy(test_session)
    return 0 if test_session.total_answered.zero?
    ((test_session.correct_answers.to_f / test_session.total_answered) * 100).round(2)
  end

  def calculate_duration(test_session)
    return 0 unless test_session.started_at && test_session.completed_at
    ((test_session.completed_at - test_session.started_at) / 60).round(2) # in minutes
  end

  def calculate_progress_percentage(test_session)
    return 0 if test_session.total_questions.zero?
    ((test_session.total_answered.to_f / test_session.total_questions) * 100).round(2)
  end

  def estimate_completion_time(test_session)
    return nil unless test_session.started_at && test_session.total_answered > 0

    elapsed = Time.current - test_session.started_at
    time_per_question = elapsed / test_session.total_answered
    remaining_questions = test_session.total_questions - test_session.total_answered

    (remaining_questions * time_per_question / 60).round(2) # in minutes
  end

  def upcoming_exams_count
    # Would need ExamSchedule model
    0
  end

  def weak_concepts_count
    @user.user_masteries.where(status: 'weak').count
  end

  def recommendations_count
    # Would need Recommendation model
    0
  end

  def unread_achievements_count
    # Would need Achievement tracking
    0
  end
end
