class TestQuestion < ApplicationRecord
  belongs_to :test_session
  belongs_to :question
  has_one :test_answer, dependent: :destroy

  validates :question_number, presence: true, numericality: { greater_than: 0 }

  # JSON column (shuffled_options) - auto-serialized by Rails

  scope :answered, -> { joins(:test_answer) }
  scope :unanswered, -> { left_joins(:test_answer).where(test_answers: { id: nil }) }
  scope :marked, -> { where(is_marked: true) }
  scope :ordered, -> { order(:question_number) }

  # Instance methods
  def answered?
    test_answer.present?
  end

  def correct?
    test_answer&.is_correct?
  end

  def mark!
    update!(is_marked: true)
  end

  def unmark!
    update!(is_marked: false)
  end

  def submit_answer(selected_option)
    # Create or update answer
    answer = test_answer || build_test_answer

    # Check if answer is correct
    correct_answer = shuffled_options['correct_answer']
    answer.selected_answer = selected_option
    answer.is_correct = (selected_option == correct_answer)
    answer.answered_at = Time.current
    answer.save!

    # Update test session stats
    test_session.calculate_score!

    answer
  end

  def time_spent
    test_answer&.time_spent || 0
  end

  # Get the original question text
  def question_text
    question.content
  end

  # Get shuffled options for display
  def display_options
    shuffled_options['options'] || question.options
  end

  # Get the correct answer
  def correct_answer
    shuffled_options['correct_answer'] || question.answer
  end

  # Check if this is the current question
  def current?
    test_session.test_questions.unanswered.ordered.first == self
  end

  # Navigation helpers
  def next_question
    test_session.test_questions
      .where('question_number > ?', question_number)
      .ordered
      .first
  end

  def previous_question
    test_session.test_questions
      .where('question_number < ?', question_number)
      .ordered
      .last
  end
end