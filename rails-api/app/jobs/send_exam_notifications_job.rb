class SendExamNotificationsJob < ApplicationJob
  queue_as :notifications

  # 모든 준비된 알림 전송
  def perform
    notifications_to_send = ExamNotification.ready_to_send

    Rails.logger.info "[NotificationJob] Found #{notifications_to_send.count} notifications to send"

    notifications_to_send.find_each do |notification|
      begin
        send_notification(notification)
      rescue => e
        Rails.logger.error "[NotificationJob] Failed to send notification #{notification.id}: #{e.message}"
        notification.update(
          status: 'failed',
          metadata: { error: e.message, failed_at: Time.current.iso8601 }
        )
      end
    end
  end

  # 특정 알림 전송
  def perform_single(notification_id)
    notification = ExamNotification.find(notification_id)
    send_notification(notification)
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "[NotificationJob] Notification not found: #{notification_id}"
  end

  private

  def send_notification(notification)
    return unless notification.can_send?

    Rails.logger.info "[NotificationJob] Sending #{notification.notification_type} notification to user #{notification.user_id}"

    case notification.channel
    when 'email'
      send_email_notification(notification)
    when 'push'
      send_push_notification(notification)
    when 'sms'
      send_sms_notification(notification)
    else
      Rails.logger.warn "[NotificationJob] Unknown channel: #{notification.channel}"
      return
    end

    # 전송 성공 시 상태 업데이트
    notification.update!(
      status: 'sent',
      sent_at: Time.current
    )

    Rails.logger.info "[NotificationJob] Successfully sent notification #{notification.id}"
  end

  def send_email_notification(notification)
    CertificationMailer.exam_notification(notification).deliver_now
  end

  def send_push_notification(notification)
    # TODO: 푸시 알림 서비스 연동
    # 예: OneSignal, Firebase Cloud Messaging 등
    Rails.logger.info "[NotificationJob] Push notification would be sent here"

    # 임시 구현 - 실제로는 푸시 서비스 API 호출
    if notification.user.push_token.present?
      # PushService.send(
      #   token: notification.user.push_token,
      #   title: notification.exam_schedule.certification.name,
      #   body: notification.message,
      #   data: { notification_id: notification.id }
      # )
    end
  end

  def send_sms_notification(notification)
    # TODO: SMS 서비스 연동
    # 예: Twilio, Naver Cloud Platform SMS 등
    Rails.logger.info "[NotificationJob] SMS would be sent here"

    # 임시 구현 - 실제로는 SMS 서비스 API 호출
    if notification.user.phone_number.present?
      # SmsService.send(
      #   to: notification.user.phone_number,
      #   message: notification.message
      # )
    end
  end
end