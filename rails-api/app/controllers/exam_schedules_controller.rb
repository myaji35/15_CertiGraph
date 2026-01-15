class ExamSchedulesController < ApplicationController
  before_action :set_exam_schedule, only: [:show, :register_notification]

  # GET /exam_schedules
  # 전체 시험 일정 조회 (캘린더 뷰용)
  def index
    @schedules = ExamSchedule.includes(:certification)

    # 연도 필터 (기본: 현재 연도)
    year = params[:year]&.to_i || Date.current.year
    @schedules = @schedules.by_year(year)

    # 월 필터 (선택사항)
    if params[:month].present?
      month = params[:month].to_i
      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month
      @schedules = @schedules.where(exam_date: start_date..end_date)
    end

    # 카테고리 필터
    if params[:category].present?
      @schedules = @schedules.joins(:certification)
                            .where(certifications: { category: params[:category] })
    end

    # 시험 타입 필터
    @schedules = @schedules.by_type(params[:exam_type]) if params[:exam_type].present?

    # 정렬
    @schedules = @schedules.order(exam_date: :asc)

    render json: {
      year: year,
      month: params[:month],
      total: @schedules.count,
      schedules: @schedules.map(&:to_calendar_event)
    }
  end

  # GET /exam_schedules/upcoming
  # 다가오는 시험 일정 (대시보드용)
  def upcoming
    limit = params[:limit]&.to_i || 10
    @schedules = ExamSchedule.upcoming
                            .includes(:certification)
                            .limit(limit)

    render json: {
      upcoming_exams: @schedules.map(&:to_json_summary)
    }
  end

  # GET /exam_schedules/open_registrations
  # 현재 원서 접수 중인 시험
  def open_registrations
    @schedules = ExamSchedule.open_registration
                            .includes(:certification)

    render json: {
      open_registrations: @schedules.map do |schedule|
        schedule.to_json_summary.merge(
          days_left: (schedule.registration_end_date - Date.current).to_i
        )
      end
    }
  end

  # GET /exam_schedules/:id
  def show
    render json: {
      schedule: @exam_schedule.as_json(
        include: {
          certification: {
            only: [:id, :name, :organization, :category]
          }
        }
      ),
      d_day: @exam_schedule.d_day_text,
      registration_open: @exam_schedule.registration_open?
    }
  end

  # POST /exam_schedules/:id/register_notification
  # 알림 등록
  def register_notification
    return render_unauthorized unless current_user

    notification_type = params[:notification_type]
    channel = params[:channel] || 'email'

    # 이미 등록된 알림인지 확인
    existing = ExamNotification.find_by(
      user: current_user,
      exam_schedule: @exam_schedule,
      notification_type: notification_type,
      status: 'pending'
    )

    if existing
      return render json: {
        success: false,
        message: 'Already registered for this notification'
      }, status: :unprocessable_entity
    end

    # 알림 스케줄링 시간 계산
    scheduled_at = calculate_notification_time(notification_type)

    notification = ExamNotification.create!(
      user: current_user,
      exam_schedule: @exam_schedule,
      notification_type: notification_type,
      channel: channel,
      scheduled_at: scheduled_at,
      status: 'pending'
    )

    render json: {
      success: true,
      notification: notification.as_json(only: [:id, :notification_type, :channel, :scheduled_at])
    }
  rescue => e
    render json: {
      success: false,
      error: e.message
    }, status: :unprocessable_entity
  end

  # GET /exam_schedules/calendar/:year/:month
  # 월별 캘린더 데이터
  def calendar
    year = params[:year].to_i
    month = params[:month].to_i

    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    @schedules = ExamSchedule.includes(:certification)
                            .where(exam_date: start_date..end_date)
                            .order(exam_date: :asc)

    # 날짜별로 그룹핑
    schedules_by_date = @schedules.group_by { |s| s.exam_date.day }

    render json: {
      year: year,
      month: month,
      days: schedules_by_date.transform_values do |schedules|
        schedules.map { |s| s.to_calendar_event }
      end
    }
  end

  # GET /exam_schedules/years
  # 사용 가능한 연도 목록
  def years
    years = ExamSchedule.distinct.pluck(:year).sort
    current_year = Date.current.year

    # 현재 연도와 다음 연도가 없으면 추가
    years << current_year unless years.include?(current_year)
    years << (current_year + 1) unless years.include?(current_year + 1)

    render json: {
      years: years.sort,
      current_year: current_year
    }
  end

  private

  def set_exam_schedule
    @exam_schedule = ExamSchedule.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Exam schedule not found' }, status: :not_found
  end

  def render_unauthorized
    render json: { error: 'Please login to register notifications' }, status: :unauthorized
  end

  def calculate_notification_time(notification_type)
    case notification_type
    when 'registration_open'
      # 원서 접수 3일 전
      @exam_schedule.registration_start_date - 3.days
    when 'exam_reminder_week'
      # 시험 1주일 전
      @exam_schedule.exam_date - 1.week
    when 'exam_reminder_month'
      # 시험 1개월 전
      @exam_schedule.exam_date - 1.month
    when 'result_announcement'
      # 결과 발표일 당일
      @exam_schedule.result_date
    else
      raise "Invalid notification type: #{notification_type}"
    end
  end
end
