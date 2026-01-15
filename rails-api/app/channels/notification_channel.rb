# app/channels/notification_channel.rb
# Handles real-time notifications for users

class NotificationChannel < ApplicationCable::Channel
  def subscribed
    # Each user gets their own notification stream
    stream_for current_user
  end

  def unsubscribed
    stop_all_streams
  end

  # Mark notification as read
  def mark_read(data)
    notification = Notification.find_by(id: data['notification_id'])

    if notification && notification.user_id == current_user.id
      notification.update(read_at: Time.current)

      broadcast_read_confirmation(notification)
    end
  end

  # Mark all notifications as read
  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current)

    NotificationChannel.broadcast_to(
      current_user,
      {
        type: 'all_marked_read',
        timestamp: Time.current.iso8601
      }
    )
  end

  # Client requests unread count
  def request_unread_count
    count = current_user.notifications.unread.count

    NotificationChannel.broadcast_to(
      current_user,
      {
        type: 'unread_count',
        count: count,
        timestamp: Time.current.iso8601
      }
    )
  end

  private

  def broadcast_read_confirmation(notification)
    NotificationChannel.broadcast_to(
      current_user,
      {
        type: 'notification_read',
        notification_id: notification.id,
        timestamp: Time.current.iso8601
      }
    )
  end
end
