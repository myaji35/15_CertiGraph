class ExamSchedulesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]

  def index
    @year = params[:year] || 2026
    @certification = params[:certification]

    @schedules = ExamSchedule.where(exam_year: @year)
    @schedules = @schedules.where(certification_name: @certification) if @certification.present?

    # 가장 가까운 시험일정 순으로 정렬
    @schedules = @schedules.order(:written_exam_date)

    # 필터용 자격증 목록
    @certifications = ExamSchedule.where(exam_year: @year)
                                  .select(:certification_name)
                                  .distinct
                                  .pluck(:certification_name)
                                  .sort

    # 통계 데이터
    @stats = {
      total_schedules: @schedules.count,
      total_certifications: @schedules.select(:certification_code).distinct.count,
      upcoming_exam: @schedules.where('written_exam_date >= ?', Date.today).first
    }

    respond_to do |format|
      format.html
      format.json { render json: @schedules }
    end
  end

  def show
    @schedule = ExamSchedule.find(params[:id])

    # 같은 자격증의 다른 회차 정보
    @other_rounds = ExamSchedule.where(
      certification_code: @schedule.certification_code,
      exam_year: @schedule.exam_year
    ).where.not(id: @schedule.id).order(:exam_round)

    # D-Day 계산
    if @schedule.written_exam_date
      days_until = (@schedule.written_exam_date - Date.today).to_i
      @d_day = if days_until > 0
        "D-#{days_until}"
      elsif days_until == 0
        "D-Day"
      else
        "종료"
      end
    end
  end

  def calendar
    @year = params[:year]&.to_i || 2026
    @month = params[:month]&.to_i || Date.today.month

    # 해당 월의 시험일정
    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month

    @exam_dates = ExamSchedule.where(exam_year: @year)
                              .where(
                                '(written_exam_date BETWEEN ? AND ?) OR (practical_exam_date BETWEEN ? AND ?)',
                                start_date, end_date, start_date, end_date
                              )

    @registration_dates = ExamSchedule.where(exam_year: @year)
                                      .where(
                                        '(written_exam_reg_start BETWEEN ? AND ?) OR (practical_exam_reg_start BETWEEN ? AND ?)',
                                        start_date, end_date, start_date, end_date
                                      )
  end

  def my_schedules
    @user_certifications = current_user.interested_certifications || []

    @schedules = ExamSchedule.where(
      certification_code: @user_certifications,
      exam_year: 2026
    ).order(:written_exam_date)

    @upcoming = @schedules.where('written_exam_date >= ?', Date.today).limit(5)
  end

  def add_interest
    certification_code = params[:certification_code]

    current_user.interested_certifications ||= []
    unless current_user.interested_certifications.include?(certification_code)
      current_user.interested_certifications << certification_code
      current_user.save
    end

    redirect_to exam_schedules_path, notice: '관심 자격증에 추가되었습니다.'
  end

  def remove_interest
    certification_code = params[:certification_code]

    if current_user.interested_certifications
      current_user.interested_certifications.delete(certification_code)
      current_user.save
    end

    redirect_to my_exam_schedules_path, notice: '관심 자격증에서 제거되었습니다.'
  end

  private

  def schedule_params
    params.require(:exam_schedule).permit(:certification_code, :year, :month)
  end
end