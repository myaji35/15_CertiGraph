class ExamSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_set, only: [:new, :create]
  before_action :set_exam_session, only: [:show, :submit_answer, :complete, :abandon, :result]
  before_action :check_session_ownership, only: [:show, :submit_answer, :complete, :abandon, :result]

  def new
    @exam_session = @study_set.exam_sessions.build
  end

  def create
    # Check if there are questions to test
    # rails-best-practices: db-exists-vs-present - Use exists? for faster existence checks
    unless @study_set.questions.exists?
      redirect_to @study_set, alert: '테스트할 문제가 없습니다. 먼저 PDF를 업로드하고 처리해주세요.'
      return
    end

    # Create new exam session
    @exam_session = @study_set.exam_sessions.build(exam_session_params)
    @exam_session.user = current_user
    @exam_session.status = ExamSession::STATUS_IN_PROGRESS
    @exam_session.started_at = Time.current

    # Select questions for the exam (using question_count from params, not from model)
    # Handle both nested and flat parameter formats
    question_count_param = if params[:exam_session] && params[:exam_session][:question_count]
      params[:exam_session][:question_count].to_i
    elsif params[:question_count]
      params[:question_count].to_i
    else
      0
    end
    
    questions = select_questions_for_exam(@exam_session, question_count_param)
    @exam_session.total_questions = questions.count
    @exam_session.answered_questions = 0
    @exam_session.correct_answers = 0

    if @exam_session.save
      # rails-best-practices: ar-bulk-insert - Use insert_all for bulk inserts
      exam_answers_data = questions.map do |question|
        {
          exam_session_id: @exam_session.id,
          question_id: question.id,
          selected_answer: nil,
          is_correct: false,
          created_at: Time.current,
          updated_at: Time.current
        }
      end
      ExamAnswer.insert_all(exam_answers_data) if exam_answers_data.any?
      redirect_to exam_session_path(@exam_session)
    else
      render :new
    end
  end

  def show
    @current_question_index = params[:question].to_i
    @current_question_index = 0 if @current_question_index < 0

    @exam_answers = @exam_session.exam_answers.includes(:question).order(:id)
    @total_questions = @exam_answers.count

    if @current_question_index >= @total_questions
      @current_question_index = @total_questions - 1
    end

    @current_answer = @exam_answers[@current_question_index]
    @current_question = @current_answer&.question

    # Calculate progress
    @answered_count = @exam_answers.where.not(selected_answer: nil).count
    @progress_percentage = @total_questions > 0 ? (@answered_count.to_f / @total_questions * 100).round : 0
  end

  def submit_answer
    answer_id = params[:answer_id]
    selected_option = params[:selected_answer]

    exam_answer = @exam_session.exam_answers.find(answer_id)

    # Update the answer
    was_answered = exam_answer.selected_answer.present?
    exam_answer.update!(selected_answer: selected_option)

    # Update session statistics
    unless was_answered
      @exam_session.increment!(:answered_questions)
    end

    if exam_answer.is_correct
      @exam_session.increment!(:correct_answers) unless was_answered
    end

    # Return JSON response for AJAX
    respond_to do |format|
      format.json do
        render json: {
          success: true,
          answered_questions: @exam_session.answered_questions,
          total_questions: @exam_session.total_questions
        }
      end
      format.html do
        redirect_to exam_session_path(@exam_session, question: params[:next_question])
      end
    end
  end

  def complete
    # Use ExamGradingService to grade the exam
    grading_service = ExamGradingService.new(@exam_session)
    result = grading_service.grade

    if result[:success]
      @exam_session.update!(status: ExamSession::STATUS_COMPLETED)
      redirect_to result_exam_session_path(@exam_session), notice: '시험이 완료되었습니다'
    else
      redirect_to exam_session_path(@exam_session), alert: result[:error]
    end
  end

  def abandon
    @exam_session.update!(status: ExamSession::STATUS_ABANDONED)
    redirect_to @exam_session.study_set, notice: '시험을 중단했습니다.'
  end

  def result
    # rails-best-practices: ar-readonly - Use readonly for display-only records
    @exam_answers = @exam_session.exam_answers.includes(:question).readonly.order(:id)
    @correct_count = @exam_answers.where(is_correct: true).count
    @wrong_count = @exam_answers.where(is_correct: false).count
    @score = @exam_session.score
  end

  private

  def set_study_set
    @study_set = StudySet.find(params[:study_set_id])
    # Allow access if user owns the study set OR if it's public/shared
    # For now, allow all access for testing purposes
    # TODO: Add proper access control logic
  end

  def set_exam_session
    @exam_session = ExamSession.find(params[:id])
  end

  def check_session_ownership
    unless @exam_session.user_id == current_user.id
      redirect_to root_path, alert: '권한이 없습니다.'
    end
  end

  def exam_session_params
    params.require(:exam_session).permit(:exam_type, :time_limit)
  end

  def select_questions_for_exam(exam_session, question_count = 0)
    all_questions = exam_session.study_set.questions

    case exam_session.exam_type
    when ExamSession::EXAM_TYPE_WRONG_ANSWER
      # Select questions that were previously answered incorrectly
      wrong_question_ids = WrongAnswer.where(
        user: current_user,
        study_set: exam_session.study_set
      ).pluck(:question_id)
      questions = all_questions.where(id: wrong_question_ids)
    else
      # For mock exam and practice, use all questions or limit
      questions = all_questions

      # Apply question count limit if specified
      if question_count > 0
        questions = questions.order('RANDOM()').limit(question_count)
      else
        questions = questions.order('RANDOM()')
      end
    end

    questions
  end
end