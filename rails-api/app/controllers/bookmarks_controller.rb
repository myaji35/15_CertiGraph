class BookmarksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_test_session, only: [:index, :create, :toggle]
  before_action :set_bookmark, only: [:show, :update, :destroy]

  # GET /test_sessions/:test_session_id/bookmarks
  def index
    @bookmarks = @test_session.question_bookmarks
      .active
      .includes(:test_question, :question)
      .order('test_questions.question_number')

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          bookmarks: @bookmarks.map { |b| format_bookmark(b) },
          count: @bookmarks.count
        }
      end
      format.html
    end
  end

  # GET /bookmarks/:id
  def show
    respond_to do |format|
      format.json { render json: { success: true, bookmark: format_bookmark(@bookmark) } }
      format.html
    end
  end

  # POST /test_sessions/:test_session_id/bookmarks
  def create
    test_question = @test_session.test_questions.find(params[:test_question_id])

    result = QuestionBookmark.toggle_bookmark(
      user: current_user,
      test_question: test_question,
      reason: params[:reason]
    )

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          action: result[:action],
          bookmark: result[:bookmark] ? format_bookmark(result[:bookmark]) : nil,
          bookmark_count: @test_session.reload.bookmark_count
        }
      end
      format.html do
        if result[:action] == 'created'
          redirect_to test_session_path(@test_session), notice: 'Bookmark added'
        else
          redirect_to test_session_path(@test_session), notice: 'Bookmark removed'
        end
      end
    end
  end

  # POST /test_sessions/:test_session_id/bookmarks/toggle
  def toggle
    test_question = @test_session.test_questions.find(params[:test_question_id])

    result = QuestionBookmark.toggle_bookmark(
      user: current_user,
      test_question: test_question,
      reason: params[:reason]
    )

    render json: {
      success: true,
      action: result[:action],
      bookmark: result[:bookmark] ? format_bookmark(result[:bookmark]) : nil,
      bookmark_count: @test_session.reload.bookmark_count
    }
  end

  # PATCH /bookmarks/:id
  def update
    if @bookmark.update(bookmark_params)
      respond_to do |format|
        format.json { render json: { success: true, bookmark: format_bookmark(@bookmark) } }
        format.html { redirect_to test_session_path(@bookmark.test_session), notice: 'Bookmark updated' }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, errors: @bookmark.errors }, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bookmarks/:id
  def destroy
    test_session = @bookmark.test_session
    @bookmark.destroy

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          message: 'Bookmark removed',
          bookmark_count: test_session.reload.bookmark_count
        }
      end
      format.html { redirect_to test_session_path(test_session), notice: 'Bookmark removed' }
    end
  end

  # GET /test_sessions/:test_session_id/bookmarks/summary
  def summary
    @test_session = current_user.test_sessions.find(params[:test_session_id])
    bookmarks = @test_session.question_bookmarks.active.includes(:test_question)

    summary_data = {
      total_bookmarks: bookmarks.count,
      answered_bookmarks: bookmarks.joins(test_question: :test_answer).count,
      unanswered_bookmarks: bookmarks.left_joins(test_question: :test_answer)
        .where(test_answers: { id: nil }).count,
      bookmarks_by_status: bookmarks.group_by { |b|
        if b.test_question.answered?
          b.test_question.correct? ? 'correct' : 'incorrect'
        else
          'unanswered'
        end
      }.transform_values(&:count)
    }

    respond_to do |format|
      format.json { render json: { success: true, summary: summary_data } }
      format.html { render partial: 'bookmarks/summary', locals: { summary: summary_data } }
    end
  end

  # GET /users/:user_id/bookmarks/all
  def all_user_bookmarks
    bookmarks = current_user.question_bookmarks
      .active
      .includes(:test_session, :test_question, :question)
      .order(bookmarked_at: :desc)
      .limit(params[:limit] || 50)

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          bookmarks: bookmarks.map { |b| format_bookmark(b, include_session: true) },
          count: bookmarks.count
        }
      end
      format.html
    end
  end

  # POST /bookmarks/batch_create
  def batch_create
    test_session = current_user.test_sessions.find(params[:test_session_id])
    question_ids = params[:question_ids] || []
    reason = params[:reason]

    created_bookmarks = []
    errors = []

    question_ids.each do |question_id|
      test_question = test_session.test_questions.find_by(id: question_id)

      if test_question
        result = QuestionBookmark.toggle_bookmark(
          user: current_user,
          test_question: test_question,
          reason: reason
        )

        if result[:action] == 'created'
          created_bookmarks << result[:bookmark]
        end
      else
        errors << "Question #{question_id} not found"
      end
    end

    render json: {
      success: errors.empty?,
      created_count: created_bookmarks.count,
      bookmarks: created_bookmarks.map { |b| format_bookmark(b) },
      errors: errors
    }
  end

  # DELETE /bookmarks/batch_destroy
  def batch_destroy
    bookmark_ids = params[:bookmark_ids] || []
    bookmarks = current_user.question_bookmarks.where(id: bookmark_ids)

    destroyed_count = bookmarks.count
    bookmarks.destroy_all

    render json: {
      success: true,
      message: "#{destroyed_count} bookmarks removed",
      destroyed_count: destroyed_count
    }
  end

  private

  def set_test_session
    @test_session = current_user.test_sessions.find(params[:test_session_id])
  end

  def set_bookmark
    @bookmark = current_user.question_bookmarks.find(params[:id])
  end

  def bookmark_params
    params.require(:bookmark).permit(:reason, :is_active)
  end

  def format_bookmark(bookmark, include_session: false)
    data = {
      id: bookmark.id,
      test_question_id: bookmark.test_question_id,
      question_id: bookmark.question_id,
      question_number: bookmark.test_question.question_number,
      reason: bookmark.reason,
      bookmarked_at: bookmark.bookmarked_at,
      is_active: bookmark.is_active,
      question: {
        id: bookmark.question.id,
        content: bookmark.question.content&.truncate(100),
        answered: bookmark.test_question.answered?,
        correct: bookmark.test_question.answered? ? bookmark.test_question.correct? : nil
      }
    }

    if include_session
      data[:test_session] = {
        id: bookmark.test_session.id,
        test_type: bookmark.test_session.test_type,
        status: bookmark.test_session.status,
        created_at: bookmark.test_session.created_at
      }
    end

    data
  end
end
