class TestSession < ApplicationRecord
  # rails-best-practices: db-counter-cache
  belongs_to :user, counter_cache: true
  belongs_to :study_set
  has_many :test_questions, dependent: :destroy
  has_many :questions, through: :test_questions
  has_many :test_answers, through: :test_questions
  has_many :question_bookmarks, dependent: :destroy

  validates :test_type, presence: true, inclusion: { in: %w[practice mock_exam review] }
  validates :question_count, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[in_progress completed abandoned paused] }

  scope :active, -> { where(status: 'in_progress') }
  scope :completed, -> { where(status: 'completed') }
  scope :paused, -> { where(status: 'paused', is_paused: true) }
  scope :recent, -> { order(created_at: :desc) }

  # JSON columns (settings, results) - auto-serialized by Rails

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

  # Pause/Resume functionality
  def pause!
    return false if is_paused || status != 'in_progress'

    self.is_paused = true
    self.paused_at = Time.current
    self.pause_count += 1
    save!
  end

  def resume!
    return false unless is_paused

    if paused_at.present?
      pause_duration = Time.current - paused_at
      self.total_pause_duration += pause_duration.to_i
    end

    self.is_paused = false
    self.resumed_at = Time.current
    self.paused_at = nil
    save!
  end

  # Auto-save functionality
  def auto_save!
    self.last_autosave_at = Time.current
    self.autosave_count += 1
    save!
  end

  # Time calculations (excluding pause time)
  def actual_time_elapsed
    return 0 unless started_at

    total_time = if completed_at
      completed_at - started_at
    else
      Time.current - started_at
    end

    # Subtract pause duration
    (total_time - total_pause_duration).to_i
  end

  def adjusted_time_remaining
    return nil unless time_limit.present? && started_at.present?

    elapsed = actual_time_elapsed
    remaining = (time_limit * 60) - elapsed
    [remaining, 0].max
  end

  # Navigation
  def current_question
    if current_question_id.present?
      test_questions.find_by(id: current_question_id)
    else
      test_questions.unanswered.ordered.first || test_questions.ordered.first
    end
  end

  def set_current_question(question_id)
    update!(current_question_id: question_id)
  end

  # Statistics
  def calculate_statistics!
    return if test_questions.count == 0

    # Calculate average time per question
    answered_questions = test_questions.joins(:test_answer)
    total_time = answered_questions.sum(:time_spent)
    avg_time = answered_questions.count > 0 ? total_time.to_f / answered_questions.count : 0

    # Calculate estimated completion time
    remaining_questions = question_count - total_answered
    estimated_remaining_seconds = remaining_questions * avg_time
    estimated_completion = Time.current + estimated_remaining_seconds.seconds

    # Count answer changes
    total_changes = test_questions.sum(:answer_change_count)

    update!(
      average_time_per_question: avg_time,
      estimated_completion_time: estimated_completion,
      answer_change_count: total_changes
    )
  end

  # Bookmarks
  def bookmarked_questions
    test_questions.joins(:question_bookmarks).where(question_bookmarks: { is_active: true })
  end

  def bookmark_question(question_id, reason: nil)
    test_question = test_questions.find_by(question_id: question_id)
    return nil unless test_question

    QuestionBookmark.toggle_bookmark(
      user: user,
      test_question: test_question,
      reason: reason
    )
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