class QuestionConcept < ApplicationRecord
  belongs_to :question
  belongs_to :knowledge_node

  validates :question_id, uniqueness: { scope: :knowledge_node_id }
  validates :importance_level, numericality: {
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 10
  }
  validates :relevance_score, numericality: {
    greater_than_or_equal_to: 0.0,
    less_than_or_equal_to: 1.0
  }
  validates :extraction_method, inclusion: { in: %w[ai manual rule_based] }

  scope :primary_concepts, -> { where(is_primary_concept: true) }
  scope :high_importance, -> { where('importance_level >= ?', 7) }
  scope :high_relevance, -> { where('relevance_score >= ?', 0.7) }
  scope :ai_extracted, -> { where(extraction_method: 'ai') }
  scope :by_concept, ->(concept_id) { where(knowledge_node_id: concept_id) }
  scope :by_question, ->(question_id) { where(question_id: question_id) }

  # Get all concepts for a question, ordered by importance
  def self.for_question(question_id)
    where(question_id: question_id)
      .includes(:knowledge_node)
      .order(importance_level: :desc, relevance_score: :desc)
  end

  # Get all questions testing a specific concept
  def self.for_concept(concept_id)
    where(knowledge_node_id: concept_id)
      .includes(:question)
      .order(importance_level: :desc)
  end

  # Find questions by concept difficulty
  def self.by_difficulty(difficulty_level)
    joins(:knowledge_node)
      .where(knowledge_nodes: { difficulty: difficulty_level })
  end

  # Calculate concept frequency across questions
  def self.concept_frequency
    group(:knowledge_node_id)
      .count
      .sort_by { |_, count| -count }
  end

  # Get concept coverage statistics
  def self.coverage_stats(study_material_id)
    joins(:knowledge_node)
      .where(knowledge_nodes: { study_material_id: study_material_id })
      .group(:knowledge_node_id)
      .select(
        'knowledge_node_id',
        'COUNT(*) as question_count',
        'AVG(importance_level) as avg_importance',
        'AVG(relevance_score) as avg_relevance'
      )
  end

  def to_json_api
    {
      id: id,
      question_id: question_id,
      concept: {
        id: knowledge_node.id,
        name: knowledge_node.name,
        level: knowledge_node.level,
        difficulty: knowledge_node.difficulty
      },
      importance_level: importance_level,
      relevance_score: relevance_score,
      is_primary_concept: is_primary_concept,
      extraction_method: extraction_method,
      metadata: metadata
    }
  end
end
