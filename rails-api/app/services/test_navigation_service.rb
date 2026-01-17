class TestNavigationService
  attr_reader :test_session

  def initialize(test_session)
    @test_session = test_session
  end

  # Get navigation grid data
  def navigation_grid
    {
      total_questions: test_session.question_count,
      current_question_number: current_question&.question_number,
      questions: question_grid_items,
      stats: grid_statistics
    }
  end

  # Get detailed question grid
  def question_grid_items
    test_session.test_questions.includes(:test_answer, :question_bookmarks).order(:question_number).map do |tq|
      {
        id: tq.id,
        question_number: tq.question_number,
        question_id: tq.question_id,
        status: question_status(tq),
        answered: tq.answered?,
        correct: tq.answered? ? tq.correct? : nil,
        marked: tq.is_marked,
        bookmarked: tq.question_bookmarks.active.any?,
        is_current: tq.id == test_session.current_question_id,
        time_spent: tq.time_spent,
        answer_changes: tq.answer_change_count,
        can_navigate: true
      }
    end
  end

  # Quick navigation to specific question
  def jump_to_question(question_number)
    test_question = test_session.test_questions.find_by(question_number: question_number)
    return { success: false, error: "Question not found" } unless test_question

    # Update current question
    test_session.set_current_question(test_question.id)

    # Start timer if not started
    unless test_question.time_started_at
      test_question.update(time_started_at: Time.current)
    end

    {
      success: true,
      question: format_question(test_question),
      navigation: navigation_context(test_question)
    }
  end

  # Get next unanswered question
  def next_unanswered
    unanswered = test_session.test_questions
      .unanswered
      .ordered
      .where('question_number > ?', current_question&.question_number || 0)
      .first

    unanswered ||= test_session.test_questions.unanswered.ordered.first

    if unanswered
      jump_to_question(unanswered.question_number)
    else
      { success: false, error: "All questions answered" }
    end
  end

  # Get next bookmarked question
  def next_bookmarked
    bookmarked = test_session.test_questions
      .joins(:question_bookmarks)
      .where(question_bookmarks: { is_active: true })
      .where('question_number > ?', current_question&.question_number || 0)
      .ordered
      .first

    bookmarked ||= test_session.test_questions
      .joins(:question_bookmarks)
      .where(question_bookmarks: { is_active: true })
      .ordered
      .first

    if bookmarked
      jump_to_question(bookmarked.question_number)
    else
      { success: false, error: "No bookmarked questions" }
    end
  end

  # Get all marked questions
  def marked_questions
    test_session.test_questions.marked.includes(:question).order(:question_number).map do |tq|
      {
        question_number: tq.question_number,
        question_id: tq.id,
        answered: tq.answered?,
        bookmarked: tq.question_bookmarks.active.any?
      }
    end
  end

  # Get review list (unanswered + bookmarked)
  def review_list
    {
      unanswered: unanswered_questions,
      bookmarked: bookmarked_questions,
      marked: marked_questions,
      total_review_items: unanswered_questions.count + bookmarked_questions.count
    }
  end

  # Batch operations
  def mark_multiple(question_numbers)
    questions = test_session.test_questions.where(question_number: question_numbers)
    questions.update_all(is_marked: true)
    { success: true, marked_count: questions.count }
  end

  def unmark_multiple(question_numbers)
    questions = test_session.test_questions.where(question_number: question_numbers)
    questions.update_all(is_marked: false)
    { success: true, unmarked_count: questions.count }
  end

  # Navigation context (for UI)
  def navigation_context(test_question = nil)
    tq = test_question || current_question
    return nil unless tq

    {
      current: {
        question_number: tq.question_number,
        total: test_session.question_count
      },
      has_previous: tq.previous_question.present?,
      has_next: tq.next_question.present?,
      previous_number: tq.previous_question&.question_number,
      next_number: tq.next_question&.question_number,
      progress_percentage: ((tq.question_number.to_f / test_session.question_count) * 100).round(1)
    }
  end

  # Keyboard navigation helpers
  def handle_keyboard_shortcut(key, context = {})
    case key
    when '1', '2', '3', '4', '5'
      # Select answer option (handled in controller)
      { action: 'select_option', option_number: key.to_i }
    when 'space', 'n'
      # Next question
      next_question = current_question&.next_question
      next_question ? jump_to_question(next_question.question_number) : { success: false }
    when 'p'
      # Previous question
      prev_question = current_question&.previous_question
      prev_question ? jump_to_question(prev_question.question_number) : { success: false }
    when 'b'
      # Toggle bookmark
      { action: 'toggle_bookmark', question_id: current_question&.id }
    when 'm'
      # Toggle mark
      { action: 'toggle_mark', question_id: current_question&.id }
    when 'u'
      # Next unanswered
      next_unanswered
    when 'r'
      # Show review list
      { action: 'show_review', data: review_list }
    else
      { success: false, error: "Unknown keyboard shortcut: #{key}" }
    end
  end

  # Filter questions
  def filter_questions(filters = {})
    questions = test_session.test_questions.includes(:test_answer, :question_bookmarks)

    questions = questions.answered if filters[:answered] == true
    questions = questions.unanswered if filters[:answered] == false
    questions = questions.marked if filters[:marked] == true
    questions = questions.joins(:question_bookmarks).where(question_bookmarks: { is_active: true }) if filters[:bookmarked] == true

    if filters[:correct] == true
      questions = questions.joins(:test_answer).where(test_answers: { is_correct: true })
    elsif filters[:correct] == false
      questions = questions.joins(:test_answer).where(test_answers: { is_correct: false })
    end

    questions.order(:question_number).map { |tq| format_question(tq) }
  end

  private

  def current_question
    @current_question ||= test_session.current_question
  end

  def question_status(test_question)
    if test_question.answered?
      test_question.correct? ? 'correct' : 'incorrect'
    elsif test_question.is_marked
      'marked'
    else
      'unanswered'
    end
  end

  def grid_statistics
    {
      answered: test_session.total_answered,
      unanswered: test_session.question_count - test_session.total_answered,
      marked: test_session.test_questions.marked.count,
      bookmarked: test_session.bookmark_count,
      correct: test_session.correct_answers,
      incorrect: test_session.total_answered - test_session.correct_answers
    }
  end

  def unanswered_questions
    test_session.test_questions.unanswered.order(:question_number).map do |tq|
      {
        question_number: tq.question_number,
        question_id: tq.id,
        marked: tq.is_marked
      }
    end
  end

  def bookmarked_questions
    test_session.test_questions
      .joins(:question_bookmarks)
      .where(question_bookmarks: { is_active: true })
      .includes(:question_bookmarks)
      .order(:question_number)
      .map do |tq|
      {
        question_number: tq.question_number,
        question_id: tq.id,
        answered: tq.answered?,
        reason: tq.question_bookmarks.active.first&.reason
      }
    end
  end

  def format_question(test_question)
    {
      id: test_question.id,
      question_number: test_question.question_number,
      question_id: test_question.question_id,
      content: test_question.question.content,
      options: test_question.display_options,
      answered: test_question.answered?,
      selected_answer: test_question.test_answer&.selected_answer,
      is_marked: test_question.is_marked,
      bookmarked: test_question.question_bookmarks.active.any?,
      time_spent: test_question.time_spent,
      navigation: navigation_context(test_question)
    }
  end
end
