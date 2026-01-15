class AnalysisResult < ApplicationRecord
  belongs_to :user
  belongs_to :question
  belongs_to :study_set
  has_many :learning_recommendations, dependent: :destroy

  validates :analysis_type, presence: true, inclusion: { in: %w(wrong_answer learning_gap concept_weakness) }
  validates :status, presence: true, inclusion: { in: %w(pending processing completed failed) }
  validates :concept_gap_score, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }
  validates :confidence_score, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }

  scope :by_type, ->(type) { where(analysis_type: type) }
  scope :by_status, ->(status) { where(status: status) }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :for_study_set, ->(study_set) { where(study_set_id: study_set.id) }
  scope :high_confidence, -> { where('confidence_score >= ?', 0.7) }
  scope :high_concept_gap, -> { where('concept_gap_score >= ?', 0.6) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_error_type, ->(error_type) { where(error_type: error_type) }

  # 분석 완료 마크
  def mark_completed!
    update!(status: 'completed')
  end

  # 분석 실패 기록
  def mark_failed!(message, backtrace = nil)
    update!(
      status: 'failed',
      error_message: message,
      error_backtrace: backtrace
    )
  end

  # 관련 개념 분석 - 그래프 탐색 결과
  def related_concepts_with_details
    return [] unless related_concepts.present?

    related_concepts.map do |concept|
      {
        concept_id: concept['concept_id'],
        name: concept['name'],
        relevance_score: concept['relevance_score'].to_f,
        relationship_type: concept['relationship_type'],
        is_prerequisite: concept['relationship_type'] == 'prerequisite',
        is_dependent: concept['relationship_type'] == 'dependent'
      }
    end
  end

  # 선수 개념 필터링
  def prerequisites
    related_concepts_with_details.select { |c| c[:is_prerequisite] }
  end

  # 종속 개념 필터링
  def dependents
    related_concepts_with_details.select { |c| c[:is_dependent] }
  end

  # 오답 패턴 분류
  def is_careless_mistake?
    error_type == 'careless'
  end

  def is_concept_gap?
    error_type == 'concept_gap'
  end

  def is_mixed_error?
    error_type == 'mixed'
  end

  # 심각도 평가
  def severity_level
    if concept_gap_score >= 0.8
      'critical'
    elsif concept_gap_score >= 0.6
      'high'
    elsif concept_gap_score >= 0.4
      'medium'
    else
      'low'
    end
  end

  # 신뢰도 기반 분석 결과 신뢰성
  def is_reliable?
    confidence_score >= 0.7
  end

  # 그래프 탐색 효율성
  def traversal_efficiency
    return 0.0 if nodes_traversed.zero?

    (related_concepts&.count || 0).to_f / nodes_traversed
  end

  # JSON 직렬화
  def to_analysis_json
    {
      id: id,
      question_id: question_id,
      analysis_type: analysis_type,
      status: status,
      error_type: error_type,
      error_description: error_description,
      concept_gap_score: concept_gap_score,
      confidence_score: confidence_score,
      severity_level: severity_level,
      related_concepts_count: related_concepts&.count || 0,
      prerequisites_count: prerequisites.count,
      dependents_count: dependents.count,
      graph_depth: graph_depth,
      nodes_traversed: nodes_traversed,
      traversal_efficiency: traversal_efficiency,
      is_reliable: is_reliable?,
      processing_time_ms: processing_time_ms,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  def to_detailed_json
    {
      **to_analysis_json,
      llm_reasoning: llm_reasoning,
      llm_analysis_metadata: llm_analysis_metadata,
      related_concepts: related_concepts_with_details,
      prerequisite_concepts: prerequisite_concepts,
      dependent_concepts: dependent_concepts,
      recommended_learning_path: recommended_learning_path,
      traversal_path: traversal_path
    }
  end
end
