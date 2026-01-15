class KnowledgeEdge < ApplicationRecord
  belongs_to :knowledge_node
  belongs_to :related_node, class_name: 'KnowledgeNode', foreign_key: 'related_node_id'

  validates :relationship_type, presence: true,
            inclusion: { in: %w(prerequisite related_to part_of example_of leads_to) }
  validates :weight, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }
  validates :related_node_id, uniqueness: { scope: [:knowledge_node_id, :relationship_type] }

  scope :by_type, ->(type) { where(relationship_type: type) }
  scope :strong_relationships, -> { where('weight > ?', 0.7) }
  scope :weak_relationships, -> { where('weight <= ?', 0.7) }
  scope :active, -> { where(active: true) }

  def relationship_name
    {
      'prerequisite' => '선수 개념',
      'related_to' => '관련 개념',
      'part_of' => '상위 개념',
      'example_of' => '예시',
      'leads_to' => '다음 개념'
    }[relationship_type] || relationship_type
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
end
