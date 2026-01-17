class TestSessionManager
  attr_reader :test_session, :errors

  def initialize(test_session)
    @test_session = test_session
    @errors = []
  end

  # Session lifecycle management
  def start_session
    return false unless test_session.status == 'in_progress'

    test_session.update(
      started_at: Time.current,
      is_paused: false
    )
  end

  def pause_session
    return add_error("Session is not in progress") unless test_session.status == 'in_progress'
    return add_error("Session is already paused") if test_session.is_paused

    if test_session.pause!
      auto_save
      true
    else
      add_error("Failed to pause session")
      false
    end
  end

  def resume_session
    return add_error("Session is not paused") unless test_session.is_paused

    if test_session.resume!
      # Resume timer for current question
      current_question = test_session.current_question
      current_question&.update(time_started_at: Time.current)
      true
    else
      add_error("Failed to resume session")
      false
    end
  end

  def complete_session
    return add_error("Session is not in progress") unless test_session.status == 'in_progress'

    test_session.complete!
    test_session.calculate_statistics!
    generate_results
    true
  rescue StandardError => e
    add_error("Failed to complete session: #{e.message}")
    false
  end

  def abandon_session(reason: nil)
    test_session.abandon!
    test_session.results = (test_session.results || {}).merge(
      abandoned_reason: reason,
      abandoned_at: Time.current
    )
    test_session.save
    true
  end

  # Auto-save functionality
  def auto_save
    test_session.auto_save!
    save_progress_snapshot
    true
  rescue StandardError => e
    add_error("Auto-save failed: #{e.message}")
    false
  end

  def should_auto_save?
    return false unless test_session.last_autosave_at

    # Auto-save every 5 minutes
    (Time.current - test_session.last_autosave_at) >= 5.minutes
  end

  # Answer management
  def submit_answer(test_question_id, selected_answer)
    test_question = test_session.test_questions.find_by(id: test_question_id)
    return add_error("Question not found") unless test_question

    # Track answer changes
    if test_question.answered? && test_question.test_answer.selected_answer != selected_answer
      test_question.increment!(:answer_change_count)
    end

    # Calculate time spent
    if test_question.time_started_at
      time_spent = (Time.current - test_question.time_started_at).to_i
      test_question.update(time_spent: time_spent)
    end

    # Submit the answer
    answer = test_question.submit_answer(selected_answer)

    # Update session statistics
    test_session.calculate_statistics!

    # Auto-save if needed
    auto_save if should_auto_save?

    { success: true, answer: answer, is_correct: answer.is_correct }
  rescue StandardError => e
    add_error("Failed to submit answer: #{e.message}")
    { success: false, error: e.message }
  end

  def change_answer(test_question_id, new_answer)
    submit_answer(test_question_id, new_answer)
  end

  # Navigation management
  def navigate_to_question(question_number)
    test_question = test_session.test_questions.find_by(question_number: question_number)
    return add_error("Question not found") unless test_question

    # Save time for previous question
    if test_session.current_question
      save_question_time(test_session.current_question)
    end

    # Set new current question
    test_session.set_current_question(test_question.id)

    # Start timer for new question
    test_question.update(time_started_at: Time.current) unless test_question.time_started_at

    test_question
  end

  def next_question
    current = test_session.current_question
    return nil unless current

    save_question_time(current)
    next_q = current.next_question

    if next_q
      test_session.set_current_question(next_q.id)
      next_q.update(time_started_at: Time.current) unless next_q.time_started_at
    end

    next_q
  end

  def previous_question
    current = test_session.current_question
    return nil unless current

    save_question_time(current)
    prev_q = current.previous_question

    if prev_q
      test_session.set_current_question(prev_q.id)
      prev_q.update(time_started_at: Time.current) unless prev_q.time_started_at
    end

    prev_q
  end

  # Bookmark management
  def toggle_bookmark(test_question_id, reason: nil)
    test_question = test_session.test_questions.find_by(id: test_question_id)
    return add_error("Question not found") unless test_question

    result = QuestionBookmark.toggle_bookmark(
      user: test_session.user,
      test_question: test_question,
      reason: reason
    )

    result
  rescue StandardError => e
    add_error("Failed to toggle bookmark: #{e.message}")
    nil
  end

  def get_bookmarked_questions
    test_session.bookmarked_questions.includes(:question).order(:question_number)
  end

  # Statistics and reporting
  def get_session_statistics
    {
      session_id: test_session.id,
      status: test_session.status,
      progress: {
        total_questions: test_session.question_count,
        answered: test_session.total_answered,
        unanswered: test_session.question_count - test_session.total_answered,
        percentage: test_session.progress_percentage
      },
      time: {
        started_at: test_session.started_at,
        actual_elapsed: test_session.actual_time_elapsed,
        paused_duration: test_session.total_pause_duration,
        time_remaining: test_session.adjusted_time_remaining,
        estimated_completion: test_session.estimated_completion_time,
        average_per_question: test_session.average_time_per_question
      },
      pause: {
        is_paused: test_session.is_paused,
        pause_count: test_session.pause_count,
        paused_at: test_session.paused_at
      },
      bookmarks: {
        count: test_session.bookmark_count,
        questions: get_bookmarked_questions.pluck(:question_number)
      },
      answers: {
        correct: test_session.correct_answers,
        total_changes: test_session.answer_change_count
      },
      autosave: {
        last_saved: test_session.last_autosave_at,
        save_count: test_session.autosave_count
      }
    }
  end

  def get_question_grid
    test_session.test_questions.includes(:test_answer, :question_bookmarks).order(:question_number).map do |tq|
      {
        question_number: tq.question_number,
        question_id: tq.id,
        answered: tq.answered?,
        marked: tq.is_marked,
        bookmarked: tq.question_bookmarks.active.any?,
        is_current: tq.id == test_session.current_question_id,
        time_spent: tq.time_spent
      }
    end
  end

  private

  def add_error(message)
    @errors << message
    Rails.logger.error("[TestSessionManager] #{message}")
    false
  end

  def save_question_time(test_question)
    return unless test_question.time_started_at

    time_spent = (Time.current - test_question.time_started_at).to_i
    test_question.update(
      time_spent: test_question.time_spent + time_spent,
      time_started_at: nil
    )
  end

  def save_progress_snapshot
    test_session.settings = (test_session.settings || {}).merge(
      last_snapshot: {
        timestamp: Time.current,
        current_question_id: test_session.current_question_id,
        answered_count: test_session.total_answered,
        elapsed_time: test_session.actual_time_elapsed
      }
    )
    test_session.save
  end

  def generate_results
    results = {
      completed_at: Time.current,
      total_time: test_session.actual_time_elapsed,
      score: test_session.score,
      pass: test_session.pass?,
      statistics: {
        total_questions: test_session.question_count,
        correct_answers: test_session.correct_answers,
        wrong_answers: test_session.question_count - test_session.correct_answers,
        unanswered: test_session.question_count - test_session.total_answered,
        answer_changes: test_session.answer_change_count,
        bookmarks: test_session.bookmark_count,
        pause_count: test_session.pause_count,
        average_time_per_question: test_session.average_time_per_question
      },
      questions: test_session.test_questions.includes(:test_answer, :question).order(:question_number).map do |tq|
        {
          question_number: tq.question_number,
          answered: tq.answered?,
          correct: tq.correct?,
          time_spent: tq.time_spent,
          answer_changes: tq.answer_change_count,
          bookmarked: tq.question_bookmarks.active.any?
        }
      end
    }

    test_session.results = results
    test_session.save
    results
  end
end
