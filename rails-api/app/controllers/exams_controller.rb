class ExamsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_exam, only: [:show, :start, :result]

  # GET /exams/create
  def new
    @exam = current_user.exam_sessions.build
    @study_sets = current_user.study_sets.includes(:study_materials)
  end

  # POST /exams
  def create
    @study_set = current_user.study_sets.find_by(id: exam_params[:study_set_id])

    unless @study_set
      render json: { error: '스터디 세트를 찾을 수 없습니다' }, status: :not_found
      return
    end

    # Use ExamGeneratorService to create exam
    generator = ExamGeneratorService.new(@study_set, current_user, exam_params)
    result = generator.generate

    if result[:success]
      @exam_session = result[:exam_session]

      respond_to do |format|
        format.html { redirect_to exam_path(@exam_session), notice: '모의고사가 생성되었습니다' }
        format.json { render json: { success: true, exam_id: @exam_session.id, redirect: exam_path(@exam_session) }, status: :created }
      end
    else
      respond_to do |format|
        format.html do
          @exam = current_user.exam_sessions.build
          @study_sets = current_user.study_sets.includes(:study_materials)
          flash[:alert] = result[:error]
          render :new
        end
        format.json { render json: { error: result[:error] }, status: :unprocessable_entity }
      end
    end
  end

  # GET /exams/:id
  def show
    # Display exam info before starting
    @questions_count = @exam_session.total_questions
    @time_limit = @exam_session.time_limit
    @exam_type = @exam_session.exam_type
    @study_set = @exam_session.study_set
  end

  # POST /exams/:id/start
  def start
    if @exam_session.status == ExamSession::STATUS_IN_PROGRESS
      redirect_to exam_session_path(@exam_session)
    else
      @exam_session.update!(
        status: ExamSession::STATUS_IN_PROGRESS,
        started_at: Time.current
      )
      redirect_to exam_session_path(@exam_session)
    end
  end

  # GET /exams/:id/result
  def result
    unless @exam_session.status == ExamSession::STATUS_COMPLETED
      redirect_to exam_path(@exam_session), alert: '시험이 완료되지 않았습니다'
      return
    end

    @exam_answers = @exam_session.exam_answers.includes(:question).order(:id)
    @correct_count = @exam_answers.where(is_correct: true).count
    @wrong_count = @exam_answers.where(is_correct: false).count
    @score = @exam_session.score
    @time_elapsed = @exam_session.formatted_time_elapsed
  end

  # GET /exams
  def index
    @exam_sessions = current_user.exam_sessions
                                 .includes(:study_set)
                                 .order(created_at: :desc)

    # Apply filters
    if params[:status].present?
      @exam_sessions = @exam_sessions.where(status: params[:status])
    end

    if params[:date_from].present?
      @exam_sessions = @exam_sessions.where('created_at >= ?', params[:date_from])
    end

    if params[:date_to].present?
      @exam_sessions = @exam_sessions.where('created_at <= ?', params[:date_to])
    end

    @exam_sessions = @exam_sessions.page(params[:page]).per(20)
  end

  # POST /exams/:id/retake
  def retake
    # Create a new exam session based on the existing one
    original_exam = @exam_session
    metadata = JSON.parse(original_exam.metadata) rescue {}

    generator = ExamGeneratorService.new(
      original_exam.study_set,
      current_user,
      {
        exam_title: "#{metadata['exam_title']} (재응시)",
        category: metadata['category'],
        question_count: original_exam.total_questions,
        time_limit: original_exam.time_limit,
        exam_type: original_exam.exam_type,
        difficulty_easy: metadata.dig('difficulty_distribution', 'easy'),
        difficulty_medium: metadata.dig('difficulty_distribution', 'medium'),
        difficulty_hard: metadata.dig('difficulty_distribution', 'hard'),
        chapter_distribution: metadata['chapter_distribution']
      }
    )

    result = generator.generate

    if result[:success]
      redirect_to exam_path(result[:exam_session]), notice: '새 모의고사가 생성되었습니다'
    else
      redirect_to exam_path(original_exam), alert: result[:error]
    end
  end

  private

  def set_exam
    @exam_session = current_user.exam_sessions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to exams_path, alert: '시험을 찾을 수 없습니다'
  end

  def exam_params
    params.require(:exam).permit(
      :study_set_id,
      :exam_title,
      :category,
      :question_count,
      :time_limit,
      :exam_type,
      :difficulty_easy,
      :difficulty_medium,
      :difficulty_hard,
      :prioritize_past_questions,
      :past_questions_ratio,
      :prevent_duplicates,
      :days_to_check,
      chapter_distribution: {}
    )
  rescue ActionController::ParameterMissing
    # Fallback for different param structure
    params.permit(
      :study_set_id,
      :'exam-title',
      :category,
      :'question-count',
      :'time-limit',
      :exam_type,
      :'difficulty-easy',
      :'difficulty-medium',
      :'difficulty-hard',
      :'prioritize-past-questions',
      :'past-questions-ratio',
      :'prevent-duplicates',
      :'days-to-check',
      chapter_distribution: {}
    ).transform_keys { |key| key.to_s.gsub('-', '_') }
  end
end
