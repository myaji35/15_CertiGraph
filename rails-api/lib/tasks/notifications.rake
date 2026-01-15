namespace :notifications do
  desc "Send all pending exam notifications"
  task send_pending: :environment do
    puts "[#{Time.current}] Starting notification check..."

    # 전송 대기 중인 알림 확인
    pending_count = ExamNotification.ready_to_send.count

    if pending_count > 0
      puts "Found #{pending_count} notifications to send"
      SendExamNotificationsJob.perform_now
    else
      puts "No notifications to send at this time"
    end

    puts "[#{Time.current}] Notification check completed"
  end

  desc "Schedule exam notifications for upcoming exams"
  task schedule_upcoming: :environment do
    puts "[#{Time.current}] Scheduling notifications for upcoming exams..."

    # 다음 30일 이내의 시험 일정 조회
    upcoming_exams = ExamSchedule.where(
      exam_date: Date.current..(Date.current + 30.days)
    ).includes(:certification)

    scheduled_count = 0

    upcoming_exams.each do |exam_schedule|
      # 관심 사용자 찾기 (실제로는 User 모델에 interested_certifications 관계 필요)
      # 여기서는 모든 활성 사용자에게 알림 생성 (개발 테스트용)
      User.where(active: true).find_each do |user|
        # 1주일 전 알림
        if exam_schedule.exam_date > Date.current + 7.days
          notification = ExamNotification.find_or_create_by(
            user: user,
            exam_schedule: exam_schedule,
            notification_type: 'exam_reminder_week'
          ) do |n|
            n.channel = 'email'
            n.scheduled_at = exam_schedule.exam_date - 7.days
            n.status = 'pending'
          end
          scheduled_count += 1 if notification.persisted?
        end

        # 1개월 전 알림
        if exam_schedule.exam_date > Date.current + 30.days
          notification = ExamNotification.find_or_create_by(
            user: user,
            exam_schedule: exam_schedule,
            notification_type: 'exam_reminder_month'
          ) do |n|
            n.channel = 'email'
            n.scheduled_at = exam_schedule.exam_date - 30.days
            n.status = 'pending'
          end
          scheduled_count += 1 if notification.persisted?
        end
      end
    end

    puts "Scheduled #{scheduled_count} new notifications"
    puts "[#{Time.current}] Scheduling completed"
  end

  desc "Clean up old notifications (older than 3 months)"
  task cleanup: :environment do
    puts "[#{Time.current}] Cleaning up old notifications..."

    old_notifications = ExamNotification.where(
      'created_at < ? AND status IN (?)',
      3.months.ago,
      ['sent', 'cancelled', 'failed']
    )

    count = old_notifications.count
    old_notifications.destroy_all

    puts "Removed #{count} old notifications"
    puts "[#{Time.current}] Cleanup completed"
  end

  desc "Show notification statistics"
  task stats: :environment do
    puts "\n=== Exam Notification Statistics ==="
    puts "Total notifications: #{ExamNotification.count}"
    puts "Pending: #{ExamNotification.pending.count}"
    puts "Sent: #{ExamNotification.sent.count}"
    puts "Failed: #{ExamNotification.failed.count}"
    puts "Cancelled: #{ExamNotification.cancelled.count}"

    puts "\n=== By Type ==="
    ExamNotification.group(:notification_type).count.each do |type, count|
      puts "#{ExamNotification.notification_types[type.to_sym]}: #{count}"
    end

    puts "\n=== By Channel ==="
    ExamNotification.group(:channel).count.each do |channel, count|
      puts "#{ExamNotification.channels[channel.to_sym]}: #{count}"
    end

    puts "\n=== Next 10 Scheduled Notifications ==="
    ExamNotification.pending
                    .where('scheduled_at > ?', Time.current)
                    .order(:scheduled_at)
                    .limit(10)
                    .each do |notification|
      puts "- #{notification.scheduled_at.strftime('%Y-%m-%d %H:%M')} | " \
           "#{notification.notification_type} | " \
           "User ##{notification.user_id} | " \
           "#{notification.exam_schedule.certification.name}"
    end
  end

  desc "Test notification sending (sends one test notification)"
  task test_send: :environment do
    puts "Creating test notification..."

    # 테스트용 사용자와 시험 일정 찾기
    user = User.first
    exam_schedule = ExamSchedule.first

    unless user && exam_schedule
      puts "Error: Need at least one user and one exam schedule in the database"
      exit
    end

    # 테스트 알림 생성
    notification = ExamNotification.create!(
      user: user,
      exam_schedule: exam_schedule,
      notification_type: 'exam_reminder_week',
      channel: 'email',
      scheduled_at: Time.current - 1.minute, # 과거 시간으로 설정하여 바로 전송되도록
      status: 'pending',
      message: "테스트 알림입니다. #{exam_schedule.certification.name} 시험이 7일 후입니다."
    )

    puts "Test notification created: ##{notification.id}"
    puts "Sending test notification..."

    SendExamNotificationsJob.perform_now

    notification.reload
    if notification.sent?
      puts "✅ Test notification sent successfully!"
    else
      puts "❌ Test notification failed: #{notification.status}"
      puts "Metadata: #{notification.metadata}"
    end
  end
end