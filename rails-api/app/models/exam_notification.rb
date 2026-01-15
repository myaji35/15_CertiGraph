class ExamNotification < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :exam_schedule

  # Validations
  validates :notification_type, presence: true
  validates :notification_type, inclusion: {
    in: %w[registration_open exam_reminder result_announcement]
  }
  validates :scheduled_at, presence: true
  validates :status, inclusion: { in: %w[pending sent failed cancelled] }
  validates :channel, inclusion: { in: %w[email push sms] }, allow_nil: true

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :sent, -> { where(status: 'sent') }
  scope :failed, -> { where(status: 'failed') }
  scope :scheduled_before, ->(time) { where('scheduled_at <= ?', time) }
  scope :ready_to_send, -> { pending.scheduled_before(Time.current) }
  scope :by_type, ->(type) { where(notification_type: type) }
  scope :by_channel, ->(channel) { where(channel: channel) }

  # Callbacks
  before_validation :set_default_channel
  before_validation :build_message, on: :create

  # Class methods
  def self.notification_types
    {
      registration_open: '원서 접수 시작',
      exam_reminder: '시험일 알림',
      result_announcement: '결과 발표'
    }
  end

  def self.channels
    {
      email: '이메일',
      push: '푸시 알림',
      sms: 'SMS'
    }
  end

  # Instance methods
  def notification_type_korean
    self.class.notification_types[notification_type.to_sym]
  end

  def channel_korean
    return '알림' unless channel
    self.class.channels[channel.to_sym]
  end

  def send_notification!
    return false unless can_send?

    begin
      case channel
      when 'email'
        send_email_notification
      when 'push'
        send_push_notification
      when 'sms'
        send_sms_notification
      end

      update!(status: 'sent', sent_at: Time.current)
      true
    rescue => e
      update!(status: 'failed', metadata: { error: e.message })
      false
    end
  end

  def can_send?
    pending? && scheduled_at <= Time.current
  end

  def pending?
    status == 'pending'
  end

  def sent?
    status == 'sent'
  end

  def failed?
    status == 'failed'
  end

  def cancelled?
    status == 'cancelled'
  end

  def cancel!
    update!(status: 'cancelled') if pending?
  end

  def reschedule!(new_time)
    update!(scheduled_at: new_time, status: 'pending') if can_reschedule?
  end

  def can_reschedule?
    pending? || failed?
  end

  private

  def set_default_channel
    self.channel ||= 'email'
  end

  def build_message
    self.message ||= generate_message
  end

  def generate_message
    cert_name = exam_schedule.certification.name
    exam_type = exam_schedule.exam_type_korean
    exam_date = exam_schedule.exam_date&.strftime('%Y년 %m월 %d일')

    case notification_type
    when 'registration_open'
      registration_start = exam_schedule.registration_start_date&.strftime('%m월 %d일')
      "#{cert_name} #{exam_type} 시험 원서접수가 #{registration_start}부터 시작됩니다."
    when 'exam_reminder'
      days = exam_schedule.days_until_exam
      "#{cert_name} #{exam_type} 시험이 #{days}일 후(#{exam_date}) 시행됩니다."
    when 'result_announcement'
      result_date = exam_schedule.result_date&.strftime('%Y년 %m월 %d일')
      "#{cert_name} #{exam_type} 시험 결과가 #{result_date} 발표됩니다."
    else
      "#{cert_name} #{exam_type} 시험 관련 알림"
    end
  end

  def send_email_notification
    # TODO: Implement with ActionMailer
    CertificationMailer.exam_notification(self).deliver_later
    Rails.logger.info "Email notification sent to user #{user.id}"
  rescue => e
    Rails.logger.error "Failed to send email notification: #{e.message}"
    raise
  end

  def send_push_notification
    # TODO: Implement with push notification service
    Rails.logger.info "Push notification sent to user #{user.id}"
  end

  def send_sms_notification
    # TODO: Implement with SMS service (e.g., Twilio)
    Rails.logger.info "SMS notification sent to user #{user.id}"
  end
end