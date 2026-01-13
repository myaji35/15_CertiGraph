class TestSession < ApplicationRecord
  belongs_to :user
  belongs_to :study_set
  has_many :test_questions, dependent: :destroy
  has_many :questions, through: :test_questions
  has_many :test_answers, through: :test_questions

  validates :test_type, presence: true, inclusion: { in: %w[practice mock_exam review] }
  validates :question_count, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[in_progress completed abandoned] }

  scope :active, -> { where(status: 'in_progress') }
  scope :completed, -> { where(status: 'completed') }
  scope :recent, -> { order(created_at: :desc) }

  # JSON serialization for settings and results (Rails 7 syntax)
  serialize :settings, coder: JSON
  serialize :results, coder: JSON

  # Callbacks
  before_validation :set_defaults, on: :create
  after_create :generate_test_questions

  # Instance methods
  def complete!
    self.completed_at = Time.current
    self.status = 'completed'
    calculate_score!
    save!
  end

  def abandon!
    self.status = 'abandoned'
    self.completed_at = Time.current
    save!
  end

  def calculate_score!
    return if test_questions.count == 0

    answered = test_questions.joins(:test_answer)
    self.total_answered = answered.count
    self.correct_answers = answered.joins(:test_answer).where(test_answers: { is_correct: true }).count
    self.score = (correct_answers.to_f / question_count * 100).round(2)
  end

  def time_remaining
    return nil unless time_limit.present? && started_at.present?

    elapsed_seconds = Time.current - started_at
    remaining_seconds = (time_limit * 60) - elapsed_seconds
    [remaining_seconds.to_i, 0].max
  end

  def time_expired?
    time_limit.present? && time_remaining == 0
  end

  def progress_percentage
    (total_answered.to_f / question_count * 100).round
  end

  def pass?
    score.present? && score >= 70 # 70% passing grade
  end

  private

  def set_defaults
    self.status ||= 'in_progress'
    self.started_at ||= Time.current
    self.correct_answers ||= 0
    self.total_answered ||= 0
    self.settings ||= {}
    self.results ||= {}
  end

  def generate_test_questions
    # Get available questions from study set
    available_questions = study_set.questions.limit(question_count * 2)

    # Randomly select questions
    selected_questions = available_questions.sample(question_count)

    # Create test questions
    selected_questions.each_with_index do |question, index|
      test_questions.create!(
        question: question,
        question_number: index + 1,
        shuffled_options: shuffle_options(question)
      )
    end
  end

  def shuffle_options(question)
    return {} unless question.options.present?

    # Get options and shuffle them
    options = question.options.dup
    answer_key = question.answer

    # Create mapping of shuffled options
    shuffled = options.to_a.shuffle.to_h

    # Store both shuffled options and correct answer key
    {
      options: shuffled,
      correct_answer: answer_key
    }
  end
end