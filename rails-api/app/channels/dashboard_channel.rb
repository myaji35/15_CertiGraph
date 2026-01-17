# app/channels/dashboard_channel.rb
class DashboardChannel < ApplicationCable::Channel
  def subscribed
    # Stream from user-specific dashboard channel
    stream_from "dashboard_#{current_user.id}" if current_user

    # Send initial data
    send_initial_data
  end

  def unsubscribed
    # Cleanup when channel is unsubscribed
    stop_all_streams
  end

  # Client requests statistics update
  def request_statistics(data)
    return unless current_user

    analytics = RealtimeAnalyticsService.new(current_user)
    analytics.broadcast_statistics
  end

  # Client requests chart update
  def request_chart(data)
    return unless current_user

    chart_type = data['chart_type']
    analytics = RealtimeAnalyticsService.new(current_user)
    analytics.broadcast_chart_update(chart_type)
  end

  # Client requests full dashboard refresh
  def refresh_dashboard(data)
    return unless current_user

    analytics = RealtimeAnalyticsService.new(current_user)
    analytics.broadcast_full_update
  end

  # Client requests live session progress
  def request_session_progress(data)
    return unless current_user

    session_id = data['session_id']
    test_session = current_user.test_sessions.find_by(id: session_id)
    return unless test_session

    analytics = RealtimeAnalyticsService.new(current_user)
    analytics.stream_session_progress(test_session)
  end

  # Client toggles widget visibility
  def toggle_widget(data)
    return unless current_user

    widget_id = data['widget_id']
    widget = current_user.dashboard_widgets.find_by(id: widget_id)
    return unless widget

    widget.update(visible: !widget.visible)

    transmit({
      type: 'widget_toggled',
      widget_id: widget.id,
      visible: widget.visible,
      timestamp: Time.current.iso8601
    })
  end

  # Client updates widget position
  def update_widget_position(data)
    return unless current_user

    widget_id = data['widget_id']
    new_position = data['position']

    widget = current_user.dashboard_widgets.find_by(id: widget_id)
    return unless widget

    widget.update(position: new_position)

    transmit({
      type: 'widget_position_updated',
      widget_id: widget.id,
      position: widget.position,
      timestamp: Time.current.iso8601
    })
  end

  # Client subscribes to specific chart updates
  def subscribe_to_chart(data)
    chart_type = data['chart_type']
    interval = data['interval'] || 30 # seconds

    # Store subscription preference
    @chart_subscriptions ||= {}
    @chart_subscriptions[chart_type] = interval

    transmit({
      type: 'chart_subscription_confirmed',
      chart_type: chart_type,
      interval: interval,
      timestamp: Time.current.iso8601
    })
  end

  # Ping to keep connection alive
  def ping(data)
    transmit({
      type: 'pong',
      timestamp: Time.current.iso8601
    })
  end

  private

  def send_initial_data
    return unless current_user

    analytics = RealtimeAnalyticsService.new(current_user)
    progress_analytics = ProgressAnalyticsService.new(current_user)

    initial_data = {
      type: 'initial_data',
      statistics: {
        overview: progress_analytics.overview,
        progress: progress_analytics.overall_progress,
        learning_patterns: progress_analytics.learning_patterns
      },
      widgets: current_user.dashboard_widgets.visible.ordered.as_json(
        only: [:id, :widget_type, :title, :position, :layout, :configuration]
      ),
      notifications: analytics.pending_notifications,
      active_sessions: analytics.active_sessions_count,
      timestamp: Time.current.iso8601
    }

    transmit(initial_data)
  end
end
