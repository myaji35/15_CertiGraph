class KnowledgeNode < ApplicationRecord
  belongs_to :study_material
  has_many :outgoing_edges, class_name: 'KnowledgeEdge', foreign_key: 'knowledge_node_id', dependent: :destroy
  has_many :incoming_edges, class_name: 'KnowledgeEdge', foreign_key: 'related_node_id', dependent: :destroy
  has_many :related_nodes, through: :outgoing_edges, source: :related_node
  has_many :dependent_nodes, through: :incoming_edges, source: :knowledge_node
  has_many :user_masteries, dependent: :destroy
  has_many :users, through: :user_masteries
  has_many :concept_synonyms, dependent: :destroy
  has_many :question_concepts, dependent: :destroy
  has_many :questions, through: :question_concepts

  validates :name, presence: true, uniqueness: { scope: :study_material_id }
  validates :level, inclusion: { in: %w(subject chapter concept detail) }
  validates :difficulty, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :importance, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }

  scope :by_level, ->(level) { where(level: level) }
  scope :by_difficulty, ->(difficulty) { where(difficulty: difficulty) }
  scope :active, -> { where(active: true) }
  scope :for_subject, ->(subject_name) { where(name: subject_name, level: 'subject') }
  scope :for_chapter, ->(chapter_name) { where(name: chapter_name, level: 'chapter') }
  scope :by_parent, ->(parent_name) { where(parent_name: parent_name) }
  scope :primary_concepts, -> { where(is_primary: true) }
  scope :by_category, ->(category) { where(concept_category: category) }
  scope :frequently_tested, -> { where('frequency >= ?', 5).order(frequency: :desc) }
  scope :high_confidence, -> { where('extraction_confidence >= ?', 0.8) }

  # 온톨로지 계층 구조
  # Subject -> Chapter -> Concept -> Detail
  def parents
    return [] unless parent_name.present?
    self.class.where(study_material_id: study_material_id, name: parent_name)
  end

  def children
    self.class.where(study_material_id: study_material_id, parent_name: name)
  end

  # 관계 조작
  def add_prerequisite(related_node, weight: 0.8, reasoning: nil)
    create_relationship(related_node, 'prerequisite', weight, reasoning)
  end

  def add_related_concept(related_node, weight: 0.6, reasoning: nil)
    create_relationship(related_node, 'related_to', weight, reasoning)
  end

  def add_part_of(related_node, weight: 0.9, reasoning: nil)
    create_relationship(related_node, 'part_of', weight, reasoning)
  end

  def add_example(related_node, weight: 0.5, reasoning: nil)
    create_relationship(related_node, 'example_of', weight, reasoning)
  end

  def add_leads_to(related_node, weight: 0.7, reasoning: nil)
    create_relationship(related_node, 'leads_to', weight, reasoning)
  end

  # 그래프 쿼리
  def prerequisites
    outgoing_edges.where(relationship_type: 'prerequisite').map(&:related_node)
  end

  def dependents
    incoming_edges.where(relationship_type: 'prerequisite').map(&:knowledge_node)
  end

  def all_prerequisites(visited = Set.new)
    return [] if visited.include?(id)
    visited.add(id)

    direct_prereqs = prerequisites
    indirect_prereqs = direct_prereqs.flat_map { |node| node.all_prerequisites(visited.dup) }

    (direct_prereqs + indirect_prereqs).uniq
  end

  def all_dependents(visited = Set.new)
    return [] if visited.include?(id)
    visited.add(id)

    direct_deps = dependents
    indirect_deps = direct_deps.flat_map { |node| node.all_dependents(visited.dup) }

    (direct_deps + indirect_deps).uniq
  end

  # 시각화 색상 계산
  def calculate_color(user)
    return 'gray' unless user

    mastery = user_masteries.find_by(user_id: user.id)
    return 'gray' unless mastery

    case mastery.mastery_level
    when 0.8..1.0
      'green'
    when 0..0.4
      'red'
    when 0.4..0.8
      'yellow'
    else
      'gray'
    end
  end

  # Find by synonym or normalized name
  def self.find_by_term(term, study_material_id)
    normalized = normalize_term(term)
    where(study_material_id: study_material_id)
      .where('LOWER(normalized_name) = ? OR LOWER(name) = ?', normalized, term.downcase)
      .first || ConceptSynonym.find_concept_by_synonym(term, study_material_id)
  end

  # Normalize concept name
  def self.normalize_term(term)
    term.downcase.strip.gsub(/[[:space:]]+/, ' ')
  end

  # Add synonym
  def add_synonym(synonym_name, type: 'synonym', similarity: 1.0, source: 'manual')
    concept_synonyms.create(
      synonym_name: synonym_name,
      synonym_type: type,
      similarity_score: similarity,
      source: source
    )
  end

  # Get all synonyms
  def all_names
    [name, normalized_name].compact + concept_synonyms.active.pluck(:synonym_name)
  end

  # Update frequency based on question count
  def update_frequency!
    update(frequency: question_concepts.count)
  end

  # JSON 直列化
  def to_graph_json(user = nil)
    {
      id: id,
      name: name,
      level: level,
      description: description,
      definition: definition,
      difficulty: difficulty,
      importance: importance,
      parent_name: parent_name,
      active: active,
      frequency: frequency,
      concept_category: concept_category,
      synonyms: concept_synonyms.active.pluck(:synonym_name),
      question_count: question_concepts.count,
      color: user ? calculate_color(user) : 'gray',
      mastery_level: user ? (user_masteries.find_by(user_id: user.id)&.mastery_level || 0.0) : 0.0,
      metadata: metadata
    }
  end

  def to_detailed_json(user = nil)
    mastery = user ? user_masteries.find_by(user_id: user.id) : nil

    {
      **to_graph_json(user),
      prerequisites: prerequisites.map(&:name),
      dependents: dependents.map(&:name),
      children_count: children.count,
      mastery_details: mastery ? {
        status: mastery.status,
        attempts: mastery.attempts,
        correct_attempts: mastery.correct_attempts,
        accuracy: mastery.attempts > 0 ? (mastery.correct_attempts.to_f / mastery.attempts) : 0,
        last_tested_at: mastery.last_tested_at,
        total_time_minutes: mastery.total_time_minutes
      } : nil
    }
  end

  private

  def create_relationship(related_node, relationship_type, weight, reasoning)
    return false unless related_node
    return false if related_node.id == id

    outgoing_edges.find_or_create_by(
      related_node_id: related_node.id,
      relationship_type: relationship_type
    ) do |edge|
      edge.weight = weight
      edge.reasoning = reasoning
    end
  end
end
