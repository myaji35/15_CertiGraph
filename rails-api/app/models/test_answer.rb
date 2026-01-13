class TestAnswer < ApplicationRecord
  belongs_to :test_question

  validates :selected_answer, presence: true
  validates :test_question_id, uniqueness: true

  scope :correct, -> { where(is_correct: true) }
  scope :incorrect, -> { where(is_correct: false) }
  scope :recent, -> { order(answered_at: :desc) }

  # Callbacks
  before_validation :calculate_time_spent, on: :create

  # Instance methods
  def question_text
    test_question.question.content
  end

  def correct_answer
    test_question.correct_answer
  end

  def explanation
    test_question.question.explanation
  end

  # Check if the answer was changed
  def changed_answer?(new_answer)
    selected_answer != new_answer
  end

  # Update the selected answer
  def update_answer(new_answer)
    self.selected_answer = new_answer
    self.is_correct = (new_answer == test_question.correct_answer)
    self.answered_at = Time.current
    save!
  end

  # Format time spent for display
  def formatted_time_spent
    return '0초' unless time_spent.present?

    minutes = time_spent / 60
    seconds = time_spent % 60

    if minutes > 0
      "#{minutes}분 #{seconds}초"
    else
      "#{seconds}초"
    end
  end

  private

  def calculate_time_spent
    return unless answered_at.present?

    # Calculate time since question was shown
    # This is simplified - in real app, track when question was shown
    question_started_at = test_question.test_session.started_at
    self.time_spent = (answered_at - question_started_at).to_i
  end
end