class CertificationsController < ApplicationController
  before_action :set_certification, only: [:show, :exam_schedules, :upcoming_exams]

  # GET /certifications
  def index
    @certifications = Certification.active

    # 필터링
    @certifications = @certifications.by_category(params[:category]) if params[:category].present?
    @certifications = @certifications.national if params[:national] == 'true'

    # 정렬
    case params[:sort]
    when 'popular'
      @certifications = @certifications.popular
    when 'pass_rate'
      @certifications = @certifications.with_high_pass_rate
    when 'name'
      @certifications = @certifications.order(:name)
    else
      @certifications = @certifications.order(created_at: :desc)
    end

    # 페이지네이션 (간단히 limit/offset 사용)
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 20).to_i
    offset = (page - 1) * per_page

    total_count = @certifications.count
    @certifications = @certifications.limit(per_page).offset(offset)

    render json: {
      certifications: @certifications.map(&:to_json_summary),
      meta: {
        current_page: page,
        total_pages: (total_count.to_f / per_page).ceil,
        total_count: total_count,
        categories: Certification.categories,
        organizations: Certification.organizations
      }
    }
  end

  # GET /certifications/:id
  def show
    render json: {
      certification: @certification.as_json(
        include: {
          exam_schedules: {
            only: [:id, :year, :round, :exam_type, :exam_date, :status]
          }
        }
      ),
      statistics: {
        average_pass_rate: @certification.average_pass_rate,
        total_applicants: @certification.total_applicants,
        next_exam: @certification.next_exam&.to_json_summary
      }
    }
  end

  # GET /certifications/:id/exam_schedules
  def exam_schedules
    @schedules = @certification.exam_schedules

    # 연도 필터
    @schedules = @schedules.by_year(params[:year]) if params[:year].present?

    # 타입 필터
    @schedules = @schedules.by_type(params[:exam_type]) if params[:exam_type].present?

    # 상태 필터
    case params[:status]
    when 'upcoming'
      @schedules = @schedules.upcoming
    when 'past'
      @schedules = @schedules.past
    when 'open_registration'
      @schedules = @schedules.open_registration
    else
      @schedules = @schedules.order(exam_date: :asc)
    end

    render json: {
      certification: @certification.to_json_summary,
      schedules: @schedules.map(&:to_json_summary)
    }
  end

  # GET /certifications/:id/upcoming_exams
  def upcoming_exams
    year = params[:year]&.to_i || Date.current.year
    @exams = @certification.upcoming_exams(year)

    render json: {
      certification: @certification.name,
      year: year,
      upcoming_exams: @exams.map(&:to_json_summary)
    }
  end

  # POST /certifications/sync
  # 한국산업인력공단 API와 동기화
  def sync
    return render_unauthorized unless current_user&.admin?

    year = params[:year]&.to_i || Date.current.year
    service = HrdkoreaApiService.new
    result = service.sync_exam_schedules(year)

    if result[:success]
      render json: {
        success: true,
        message: "Successfully synced #{result[:count]} schedules for year #{year}"
      }
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
  end

  # GET /certifications/search
  def search
    query = params[:q]
    return render json: { certifications: [] } if query.blank?

    @certifications = Certification.active
                                  .where('name LIKE ? OR name_en LIKE ?',
                                        "%#{query}%", "%#{query}%")
                                  .limit(10)

    render json: {
      query: query,
      results: @certifications.map(&:to_json_summary)
    }
  end

  private

  def set_certification
    @certification = Certification.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Certification not found' }, status: :not_found
  end

  def render_unauthorized
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end