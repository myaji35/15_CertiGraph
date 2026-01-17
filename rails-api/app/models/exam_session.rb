class ExamSession < ApplicationRecord
  belongs_to :study_set
  # rails-best-practices: db-counter-cache
  belongs_to :user, counter_cache: true
  has_many :exam_answers, dependent: :destroy
  has_many :questions, through: :exam_answers

  # Status constants
  STATUS_IN_PROGRESS = 'in_progress'.freeze
  STATUS_COMPLETED = 'completed'.freeze
  STATUS_ABANDONED = 'abandoned'.freeze

  # Exam types
  EXAM_TYPE_MOCK = 'mock_exam'.freeze
  EXAM_TYPE_PRACTICE = 'practice'.freeze
  EXAM_TYPE_WRONG_ANSWER = 'wrong_answer_review'.freeze

  # Randomization strategies
  RANDOMIZATION_STRATEGIES = %w[full_random constrained_random block_random].freeze

  validates :status, inclusion: { in: [STATUS_IN_PROGRESS, STATUS_COMPLETED, STATUS_ABANDONED] }
  validates :exam_type, inclusion: { in: [EXAM_TYPE_MOCK, EXAM_TYPE_PRACTICE, EXAM_TYPE_WRONG_ANSWER] }
  validates :randomization_strategy, inclusion: { in: RANDOMIZATION_STRATEGIES }, allow_nil: true

  scope :in_progress, -> { where(status: STATUS_IN_PROGRESS) }
  scope :completed, -> { where(status: STATUS_COMPLETED) }
  scope :with_randomization, -> { where(randomization_enabled: true) }
  scope :without_randomization, -> { where(randomization_enabled: false) }

  def complete!
    update!(
      status: STATUS_COMPLETED,
      completed_at: Time.current,
      score: calculate_score
    )
  end

  def calculate_score
    return 0 if total_questions.to_i == 0
    (correct_answers.to_f / total_questions * 100).round(2)
  end

  def time_elapsed
    return 0 unless started_at
    end_time = completed_at || Time.current
    (end_time - started_at).to_i
  end

  def formatted_time_elapsed
    seconds = time_elapsed
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    seconds = seconds % 60

    if hours > 0
      "#{hours}시간 #{minutes}분"
    elsif minutes > 0
      "#{minutes}분 #{seconds}초"
    else
      "#{seconds}초"
    end
  end

  # Randomization methods

  # Initialize randomization for this exam session
  def initialize_randomization!(strategy: 'full_random', enabled: true)
    self.randomization_seed = AnswerRandomizer.generate_seed
    self.randomization_strategy = strategy
    self.randomization_enabled = enabled
    save!
  end

  # Get randomizer instance for this session
  def randomizer
    return nil unless randomization_enabled? && randomization_seed.present?

    @randomizer ||= AnswerRandomizer.from_seed(
      randomization_seed,
      strategy: randomization_strategy || 'full_random'
    )
  end

  # Randomize a question's options using this session's seed
  def randomize_question(question)
    return nil unless randomizer

    randomizer.randomize_question_options(question)
  end

  # Randomize all questions in this exam
  def randomize_all_questions
    return [] unless randomizer

    exam_questions = study_set.study_material.questions
    randomizer.randomize_exam_questions(exam_questions)
  end

  # Check if randomization is enabled and configured
  def randomization_configured?
    randomization_enabled? && randomization_seed.present?
  end

  # Get randomization summary
  def randomization_summary
    {
      enabled: randomization_enabled?,
      strategy: randomization_strategy,
      seed: randomization_seed,
      configured: randomization_configured?,
      can_restore: randomization_seed.present?
    }
  end

  # Enable randomization with optional strategy
  def enable_randomization!(strategy: nil)
    self.randomization_enabled = true
    self.randomization_strategy = strategy if strategy.present?
    self.randomization_seed ||= AnswerRandomizer.generate_seed
    save!
  end

  # Disable randomization
  def disable_randomization!
    self.randomization_enabled = false
    save!
  end

  # Change randomization strategy
  def change_strategy!(new_strategy)
    return false unless RANDOMIZATION_STRATEGIES.include?(new_strategy)

    self.randomization_strategy = new_strategy
    # Generate new seed when changing strategy to ensure different results
    self.randomization_seed = AnswerRandomizer.generate_seed
    save!
  end

  # Get randomization statistics for this session
  def randomization_stats
    return {} unless study_set&.study_material

    RandomizationStat.by_material(study_set.study_material.id)
                     .group(:is_uniform)
                     .count
  end
end
