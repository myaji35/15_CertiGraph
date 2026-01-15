class LearningRecommendation < ApplicationRecord
  belongs_to :user
  belongs_to :study_set
  belongs_to :analysis_result, optional: true
  has_many :learning_recommendation_questions, dependent: :destroy
  has_many :recommended_questions, through: :learning_recommendation_questions, source: :question

  validates :recommendation_type, presence: true, inclusion: { in: %w(remedial progressive comprehensive) }
  validates :status, presence: true, inclusion: { in: %w(pending active completed dismissed) }
  validates :priority_level, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }
  validates :learning_efficiency_index, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }
  validates :success_probability, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }

  scope :by_type, ->(type) { where(recommendation_type: type) }
  scope :by_status, ->(status) { where(status: status) }
  scope :active, -> { where(status: 'active') }
  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }
  scope :accepted, -> { where(is_accepted: true) }
  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :high_priority, -> { where('priority_level >= ?', 7) }
  scope :high_efficiency, -> { where('learning_efficiency_index >= ?', 0.7) }
  scope :high_success_rate, -> { where('success_probability >= ?', 0.7) }
  scope :recent, -> { order(created_at: :desc) }
  scope :recently_started, -> { where.not(started_at: nil).order(started_at: :desc) }

  # 추천 활성화
  def activate!
    update!(status: 'active', started_at: Time.current)
  end

  # 추천 완료
  def mark_completed!
    update!(
      status: 'completed',
      completed_at: Time.current,
      progress_tracking: progress_tracking&.merge({ final_accuracy: calculate_final_accuracy })
    )
  end

  # 추천 거절
  def dismiss!
    update!(status: 'dismissed')
  end

  # 사용자 피드백 기록
  def add_feedback(feedback_text, rating)
    return false unless (1..5).include?(rating)

    update!(
      user_feedback: feedback_text,
      feedback_rating: rating,
      is_accepted: rating >= 4
    )
  end

  # 약점 개념 추출
  def weakness_concepts
    return [] unless weakness_analysis.present? && weakness_analysis['concept_gaps'].present?

    weakness_analysis['concept_gaps'].map do |gap|
      {
        concept_id: gap['concept_id'],
        name: gap['concept_name'],
        gap_score: gap['gap_score'],
        mastery_level: gap['mastery_level']
      }
    end
  end

  # 오류 패턴 분석
  def error_patterns
    weakness_analysis&.fetch('error_patterns', []) || []
  end

  # 성공 예측
  def success_predictions
    weakness_analysis&.fetch('mastery_predictions', []) || []
  end

  # 추천 학습 시간 계산
  def expected_completion_time_hours
    estimated_learning_hours
  end

  # 학습 경로 단계 수
  def learning_path_steps
    return 0 unless learning_path.present?

    if learning_path.is_a?(Array)
      learning_path.count
    elsif learning_path.is_a?(Hash)
      learning_path.fetch('steps', []).count
    else
      0
    end
  end

  # 진행 상황 추적
  def update_progress(questions_completed:, correct_count:, time_spent_minutes:)
    current_progress = progress_tracking || {}

    updated_progress = current_progress.merge({
      questions_completed: questions_completed,
      accuracy: questions_completed > 0 ? (correct_count.to_f / questions_completed * 100).round(2) : 0.0,
      time_spent_minutes: (current_progress['time_spent_minutes'] || 0) + time_spent_minutes,
      last_updated_at: Time.current.iso8601
    })

    update!(progress_tracking: updated_progress)
  end

  # 최종 정확도 계산
  def calculate_final_accuracy
    return 0.0 unless progress_tracking.present?

    progress_tracking['accuracy'] || 0.0
  end

  # 학습 효율성 평가
  def evaluate_efficiency
    return 0.0 unless completed_at && started_at

    time_taken_hours = ((completed_at - started_at) / 3600).round(2)
    efficiency = (success_probability / time_taken_hours).round(3)

    update!(learning_efficiency_index: [efficiency, 1.0].min)
    efficiency
  end

  # 개인화 스타일 정보
  def learning_style
    personalization_params&.fetch('learning_style', 'balanced') || 'balanced'
  end

  # 학습 속도
  def learning_pace
    personalization_params&.fetch('pace', 'normal') || 'normal'
  end

  # 집중력 수준
  def concentration_level
    personalization_params&.fetch('concentration_level', 'medium') || 'medium'
  end

  # 추천 상태 요약
  def status_summary
    {
      type: recommendation_type,
      status: status,
      priority: priority_level,
      efficiency: learning_efficiency_index,
      success_probability: success_probability,
      progress: progress_tracking&.fetch('accuracy', 0.0) || 0.0,
      total_questions: total_recommended_count,
      is_accepted: is_accepted,
      started: started_at.present?,
      completed: completed_at.present?
    }
  end

  # JSON 직렬화
  def to_recommendation_json
    {
      id: id,
      user_id: user_id,
      study_set_id: study_set_id,
      type: recommendation_type,
      status: status,
      priority_level: priority_level,
      total_questions: total_recommended_count,
      suggested_difficulty: suggested_difficulty,
      learning_efficiency_index: learning_efficiency_index,
      success_probability: success_probability,
      estimated_hours: estimated_learning_hours,
      is_accepted: is_accepted,
      feedback_rating: feedback_rating,
      weakness_concepts_count: weakness_concepts.count,
      error_patterns_count: error_patterns.count,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  def to_detailed_json
    {
      **to_recommendation_json,
      weakness_analysis: weakness_analysis,
      error_patterns: error_patterns,
      success_predictions: success_predictions,
      learning_path_steps: learning_path_steps,
      learning_efficiency: learning_efficiency_index,
      adaptive_params: adaptive_params,
      time_efficiency: time_efficiency,
      progress_tracking: progress_tracking,
      personalization_params: personalization_params,
      started_at: started_at,
      completed_at: completed_at
    }
  end
end
