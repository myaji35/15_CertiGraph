class ExamSession < ApplicationRecord
  belongs_to :study_set
  belongs_to :user
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

  validates :status, inclusion: { in: [STATUS_IN_PROGRESS, STATUS_COMPLETED, STATUS_ABANDONED] }
  validates :exam_type, inclusion: { in: [EXAM_TYPE_MOCK, EXAM_TYPE_PRACTICE, EXAM_TYPE_WRONG_ANSWER] }

  scope :in_progress, -> { where(status: STATUS_IN_PROGRESS) }
  scope :completed, -> { where(status: STATUS_COMPLETED) }

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
end
