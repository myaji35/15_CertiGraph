class TestSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_set, only: [:new, :create]
  before_action :set_test_session, only: [
    :show, :update, :complete, :abandon, :submit_answer,
    :pause, :resume, :auto_save, :statistics, :navigation_grid,
    :jump_to_question, :next_unanswered, :keyboard_shortcut
  ]
  before_action :initialize_services, only: [
    :pause, :resume, :auto_save, :statistics, :navigation_grid,
    :jump_to_question, :next_unanswered, :keyboard_shortcut, :submit_answer
  ]

  # GET /study_sets/:study_set_id/test_sessions/new
  def new
    @test_session = @study_set.test_sessions.build
  end

  # POST /study_sets/:study_set_id/test_sessions
  def create
    @test_session = @study_set.test_sessions.build(test_session_params)
    @test_session.user = current_user

    if @test_session.save
      redirect_to test_session_path(@test_session)
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /test_sessions/:id
  def show
    @current_question = @test_session.test_questions.unanswered.ordered.first ||
                       @test_session.test_questions.ordered.first
    @progress = @test_session.progress_percentage
    @time_remaining = @test_session.time_remaining
  end

  # PATCH /test_sessions/:id
  def update
    if @test_session.update(test_session_params)
      respond_to do |format|
        format.html { redirect_to test_session_path(@test_session) }
        format.json { render json: @test_session }
      end
    else
      respond_to do |format|
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: @test_session.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /test_sessions/:id/submit_answer
  def submit_answer
    @test_question = @test_session.test_questions.find(params[:question_id])
    @answer = @test_question.submit_answer(params[:selected_answer])

    respond_to do |format|
      format.turbo_stream do
        # Move to next question or show completion
        if params[:next_action] == 'complete'
          @test_session.complete!
          render turbo_stream: turbo_stream.replace(
            'test-content',
            partial: 'test_sessions/completed',
            locals: { test_session: @test_session }
          )
        else
          next_question = @test_question.next_question || @test_session.test_questions.unanswered.ordered.first
          if next_question
            render turbo_stream: [
              turbo_stream.replace(
                'question-display',
                partial: 'test_sessions/question',
                locals: { question: next_question, test_session: @test_session }
              ),
              turbo_stream.update(
                'progress-bar',
                partial: 'test_sessions/progress',
                locals: { test_session: @test_session }
              )
            ]
          else
            # All questions answered, show review or complete
            render turbo_stream: turbo_stream.replace(
              'test-content',
              partial: 'test_sessions/review',
              locals: { test_session: @test_session }
            )
          end
        end
      end
      format.json do
        render json: {
          success: true,
          is_correct: @answer.is_correct,
          next_question_id: @test_question.next_question&.id,
          progress: @test_session.progress_percentage
        }
      end
    end
  end

  # POST /test_sessions/:id/complete
  def complete
    @test_session.complete!

    respond_to do |format|
      format.html { redirect_to test_session_result_path(@test_session) }
      format.json { render json: @test_session }
    end
  end

  # POST /test_sessions/:id/abandon
  def abandon
    @test_session.abandon!

    respond_to do |format|
      format.html { redirect_to study_set_path(@test_session.study_set), notice: '시험을 중단했습니다.' }
      format.json { render json: @test_session }
    end
  end

  # GET /test_sessions/:id/result
  def result
    @test_session = TestSession.find(params[:id])
    @questions = @test_session.test_questions.includes(:question, :test_answer).ordered
  end

  # POST /test_sessions/:id/pause
  def pause
    if @session_manager.pause_session
      respond_to do |format|
        format.json do
          render json: {
            success: true,
            message: 'Session paused',
            paused_at: @test_session.paused_at,
            pause_count: @test_session.pause_count
          }
        end
        format.html { redirect_to test_session_path(@test_session), notice: 'Test paused' }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, errors: @session_manager.errors }, status: :unprocessable_entity }
        format.html { redirect_to test_session_path(@test_session), alert: @session_manager.errors.join(', ') }
      end
    end
  end

  # POST /test_sessions/:id/resume
  def resume
    if @session_manager.resume_session
      respond_to do |format|
        format.json do
          render json: {
            success: true,
            message: 'Session resumed',
            resumed_at: @test_session.resumed_at,
            time_remaining: @test_session.adjusted_time_remaining
          }
        end
        format.html { redirect_to test_session_path(@test_session), notice: 'Test resumed' }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, errors: @session_manager.errors }, status: :unprocessable_entity }
        format.html { redirect_to test_session_path(@test_session), alert: @session_manager.errors.join(', ') }
      end
    end
  end

  # POST /test_sessions/:id/auto_save
  def auto_save
    if @session_manager.auto_save
      render json: {
        success: true,
        message: 'Progress saved',
        last_saved_at: @test_session.last_autosave_at,
        save_count: @test_session.autosave_count
      }
    else
      render json: { success: false, errors: @session_manager.errors }, status: :unprocessable_entity
    end
  end

  # GET /test_sessions/:id/statistics
  def statistics
    stats = @session_manager.get_session_statistics

    respond_to do |format|
      format.json { render json: stats }
      format.html { render partial: 'test_sessions/statistics', locals: { statistics: stats } }
    end
  end

  # GET /test_sessions/:id/navigation_grid
  def navigation_grid
    grid = @navigation_service.navigation_grid

    respond_to do |format|
      format.json { render json: grid }
      format.html { render partial: 'test_sessions/navigation_grid', locals: { grid: grid } }
    end
  end

  # POST /test_sessions/:id/jump_to_question
  def jump_to_question
    question_number = params[:question_number].to_i
    result = @navigation_service.jump_to_question(question_number)

    respond_to do |format|
      if result[:success]
        format.json { render json: result }
        format.html do
          redirect_to test_session_path(@test_session, question: question_number)
        end
      else
        format.json { render json: result, status: :not_found }
        format.html do
          redirect_to test_session_path(@test_session), alert: result[:error]
        end
      end
    end
  end

  # POST /test_sessions/:id/next_unanswered
  def next_unanswered
    result = @navigation_service.next_unanswered

    respond_to do |format|
      if result[:success]
        format.json { render json: result }
        format.html do
          redirect_to test_session_path(@test_session, question: result[:question][:question_number])
        end
      else
        format.json { render json: result, status: :not_found }
        format.html do
          redirect_to test_session_path(@test_session), notice: 'All questions answered!'
        end
      end
    end
  end

  # POST /test_sessions/:id/keyboard_shortcut
  def keyboard_shortcut
    key = params[:key]
    context = params[:context] || {}

    result = @navigation_service.handle_keyboard_shortcut(key, context)

    render json: result
  end

  private

  def set_study_set
    @study_set = current_user.study_sets.find(params[:study_set_id])
  end

  def set_test_session
    @test_session = current_user.test_sessions.find(params[:id])
  end

  def test_session_params
    params.require(:test_session).permit(:test_type, :question_count, :time_limit, settings: {})
  end

  def initialize_services
    @session_manager = TestSessionManager.new(@test_session)
    @navigation_service = TestNavigationService.new(@test_session)
  end
end