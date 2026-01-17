class KnowledgeEdge < ApplicationRecord
  belongs_to :knowledge_node
  belongs_to :related_node, class_name: 'KnowledgeNode', foreign_key: 'related_node_id'

  validates :relationship_type, presence: true,
            inclusion: { in: %w(prerequisite related_to part_of example_of leads_to) }
  validates :weight, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }
  validates :related_node_id, uniqueness: { scope: [:knowledge_node_id, :relationship_type] }
  validates :strength, inclusion: { in: %w(mandatory recommended optional), allow_nil: true }

  scope :by_type, ->(type) { where(relationship_type: type) }
  scope :strong_relationships, -> { where('weight > ?', 0.7) }
  scope :weak_relationships, -> { where('weight <= ?', 0.7) }
  scope :active, -> { where(active: true) }
  scope :by_strength, ->(strength) { where(strength: strength) }
  scope :auto_generated, -> { where(auto_generated: true) }
  scope :user_verified, -> { where(verified_by_user: true) }
  scope :prerequisites, -> { where(relationship_type: 'prerequisite') }

  def relationship_name
    {
      'prerequisite' => '선수 개념',
      'related_to' => '관련 개념',
      'part_of' => '상위 개념',
      'example_of' => '예시',
      'leads_to' => '다음 개념'
    }[relationship_type] || relationship_type
  end

  def strength_label
    {
      'mandatory' => '필수 선수 지식',
      'recommended' => '권장 선수 지식',
      'optional' => '선택 선수 지식'
    }[strength] || '미분류'
  end

  def to_json(*args)
    {
      id: id,
      from_id: knowledge_node_id,
      from_name: knowledge_node.name,
      to_id: related_node_id,
      to_name: related_node.name,
      relationship_type: relationship_type,
      relationship_name: relationship_name,
      weight: weight,
      reasoning: reasoning,
      active: active
    }
  end

  def to_visualization_json
    {
      id: id,
      source: knowledge_node_id,
      target: related_node_id,
      type: relationship_type,
      weight: weight,
      strength: strength,
      strength_label: strength_label,
      depth: depth || 1,
      confidence: confidence_score || 0.0,
      auto_generated: auto_generated || false,
      verified: verified_by_user || false,
      reasoning: llm_reasoning || reasoning,
      metadata: metadata || {},
      active: active
    }
  end

  def to_detailed_json
    {
      **to_visualization_json,
      from_node: {
        id: knowledge_node.id,
        name: knowledge_node.name,
        level: knowledge_node.level,
        difficulty: knowledge_node.difficulty
      },
      to_node: {
        id: related_node.id,
        name: related_node.name,
        level: related_node.level,
        difficulty: related_node.difficulty
      },
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
