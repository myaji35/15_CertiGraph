class ExamSchedule < ApplicationRecord
  # Associations
  belongs_to :certification
  has_many :exam_notifications, dependent: :destroy
  has_many :notified_users, through: :exam_notifications, source: :user

  # Validations
  validates :year, presence: true
  validates :exam_type, presence: true
  validates :exam_type, inclusion: { in: %w[written practical interview] }
  validates :status, inclusion: { in: %w[scheduled in_progress completed cancelled] }

  # Scopes
  scope :upcoming, -> { where('exam_date >= ?', Date.current).order(exam_date: :asc) }
  scope :past, -> { where('exam_date < ?', Date.current).order(exam_date: :desc) }
  scope :current_year, -> { where(year: Date.current.year) }
  scope :next_year, -> { where(year: Date.current.year + 1) }
  scope :by_year, ->(year) { where(year: year) }
  scope :by_type, ->(type) { where(exam_type: type) }
  scope :open_registration, -> {
    where('registration_start_date <= ? AND registration_end_date >= ?',
          Date.current, Date.current)
  }
  scope :registration_upcoming, -> {
    where('registration_start_date > ?', Date.current)
      .order(registration_start_date: :asc)
  }

  # Callbacks
  after_create :schedule_notifications
  after_update :update_notifications, if: :saved_change_to_exam_date?

  # Class methods
  def self.exam_types
    {
      written: '필기',
      practical: '실기',
      interview: '면접'
    }
  end

  def self.statuses
    {
      scheduled: '예정',
      in_progress: '진행중',
      completed: '완료',
      cancelled: '취소'
    }
  end

  # Instance methods
  def exam_type_korean
    self.class.exam_types[exam_type.to_sym]
  end

  def status_korean
    self.class.statuses[status.to_sym]
  end

  def registration_open?
    return false unless registration_start_date && registration_end_date

    Date.current.between?(registration_start_date, registration_end_date)
  end

  def registration_closed?
    return true unless registration_end_date

    Date.current > registration_end_date
  end

  def days_until_exam
    return nil unless exam_date
    return 0 if exam_date <= Date.current

    (exam_date - Date.current).to_i
  end

  def days_until_registration
    return nil unless registration_start_date
    return 0 if registration_start_date <= Date.current

    (registration_start_date - Date.current).to_i
  end

  def d_day_text
    days = days_until_exam
    return nil unless days

    if days == 0
      'D-Day'
    elsif days > 0
      "D-#{days}"
    else
      "D+#{days.abs}"
    end
  end

  def registration_period_text
    return '미정' unless registration_start_date && registration_end_date

    "#{registration_start_date.strftime('%m/%d')} ~ #{registration_end_date.strftime('%m/%d')}"
  end

  def to_calendar_event
    {
      id: id,
      title: "#{certification.name} #{exam_type_korean}",
      start: exam_date,
      exam_time: exam_time,
      type: 'exam',
      exam_type: exam_type,
      certification_id: certification_id,
      d_day: d_day_text,
      registration_period: registration_period_text
    }
  end

  def to_json_summary
    {
      id: id,
      certification_name: certification.name,
      year: year,
      round: round,
      exam_type: exam_type,
      exam_type_korean: exam_type_korean,
      exam_date: exam_date,
      exam_time: exam_time&.strftime('%H:%M'),
      registration_period: registration_period_text,
      registration_open: registration_open?,
      days_until_exam: days_until_exam,
      d_day: d_day_text,
      status: status,
      result_date: result_date
    }
  end

  private

  def schedule_notifications
    # 원서 접수 3일 전 알림
    if registration_start_date && registration_start_date > Date.current
      schedule_notification('registration_open', registration_start_date - 3.days)
    end

    # 시험 1주일 전 알림
    if exam_date && exam_date > Date.current
      schedule_notification('exam_reminder', exam_date - 1.week)
    end

    # 시험 1개월 전 알림
    if exam_date && exam_date > Date.current + 1.month
      schedule_notification('exam_reminder', exam_date - 1.month)
    end

    # 결과 발표일 알림
    if result_date && result_date > Date.current
      schedule_notification('result_announcement', result_date)
    end
  end

  def schedule_notification(type, scheduled_at)
    # 실제 구현시 백그라운드 Job으로 처리
    Rails.logger.info "Scheduling #{type} notification for #{scheduled_at}"
  end

  def update_notifications
    # 일정 변경시 알림 재스케줄링
    exam_notifications.pending.destroy_all
    schedule_notifications
  end
end
