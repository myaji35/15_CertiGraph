class TestSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_set, only: [:new, :create]
  before_action :set_test_session, only: [:show, :update, :complete, :abandon, :submit_answer]

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
end