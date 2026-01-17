class Question < ApplicationRecord
  belongs_to :study_material
  has_many :test_questions, dependent: :destroy
  has_many :chunk_questions, dependent: :destroy
  has_many :document_chunks, through: :chunk_questions
  has_many :question_concepts, dependent: :destroy
  has_many :knowledge_nodes, through: :question_concepts
  has_many :question_passages, dependent: :destroy
  has_many :passages, through: :question_passages

  validates :content, presence: true

  # Validation statuses
  VALIDATION_STATUSES = %w[pending validated failed].freeze
  QUESTION_TYPES = %w[multiple_choice true_false short_answer].freeze

  validates :validation_status, inclusion: { in: VALIDATION_STATUSES }, allow_nil: true
  validates :question_type, inclusion: { in: QUESTION_TYPES }, allow_nil: true

  scope :by_topic, ->(topic) { where(topic: topic) }
  scope :by_difficulty, ->(level) { where(difficulty: level) }
  scope :by_type, ->(type) { where(question_type: type) }
  scope :validated, -> { where(validation_status: 'validated') }
  scope :failed, -> { where(validation_status: 'failed') }
  scope :pending, -> { where(validation_status: 'pending') }
  scope :random, -> { order(Arel.sql('RANDOM()')) }
  scope :by_number, -> { order(:question_number) }
  scope :with_passages, -> { joins(:passages).distinct }
  scope :without_passages, -> { left_joins(:passages).where(passages: { id: nil }) }

  # 벡터 임베딩을 JSON으로 저장/로드
  def embedding
    JSON.parse(embedding_json) if embedding_json.present?
  end

  def embedding=(vector)
    self.embedding_json = vector.to_json if vector.present?
  end

  # 옵션 랜덤 셔플링
  def randomized_options
    return {} unless options.present?

    # options가 Hash 형태로 저장된 경우
    # { "①" => "답안1", "②" => "답안2", ... }
    options.to_a.shuffle.to_h
  end

  # 정답 텍스트 가져오기
  def correct_answer_text
    options[answer] if options && answer
  end

  # 포맷된 옵션 반환
  def formatted_options
    return {} unless options.present?
    options
  end

  # Passage relationships
  def primary_passage
    passages.joins(:question_passages)
            .where(question_passages: { is_primary: true })
            .first
  end

  def related_passages
    passages.joins(:question_passages)
            .where(question_passages: { is_primary: false })
            .order('question_passages.relevance_score DESC')
  end

  def add_passage(passage, is_primary: false, relevance_score: 100)
    question_passages.find_or_create_by(passage: passage) do |qp|
      qp.is_primary = is_primary
      qp.relevance_score = relevance_score
    end
  end

  # Validation helpers
  def validate_question!
    errors = []

    errors << "Content is blank" if content.blank?
    errors << "Options are missing" if options.blank? && question_type == 'multiple_choice'
    errors << "Answer is missing" if answer.blank? && question_type != 'short_answer'
    errors << "Insufficient options (need at least 2)" if options.present? && options.size < 2

    if errors.any?
      update(validation_status: 'failed', validation_errors: { errors: errors })
      false
    else
      update(validation_status: 'validated', validation_errors: {})
      true
    end
  end

  def validated?
    validation_status == 'validated'
  end

  def has_passages?
    passages.any?
  end
end
