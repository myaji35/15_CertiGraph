class ConceptSynonym < ApplicationRecord
  belongs_to :knowledge_node

  validates :synonym_name, presence: true, uniqueness: { scope: :knowledge_node_id }
  validates :synonym_type, inclusion: { in: %w[synonym abbreviation alias related_term] }
  validates :similarity_score, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }
  validates :source, inclusion: { in: %w[manual ai_extracted user_defined] }

  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(synonym_type: type) }
  scope :ai_extracted, -> { where(source: 'ai_extracted') }
  scope :manual, -> { where(source: 'manual') }
  scope :high_similarity, -> { where('similarity_score >= ?', 0.8) }

  # Find knowledge node by synonym name
  def self.find_concept_by_synonym(synonym_name, study_material_id = nil)
    query = active.joins(:knowledge_node).where('LOWER(concept_synonyms.synonym_name) = ?', synonym_name.downcase)
    query = query.where(knowledge_nodes: { study_material_id: study_material_id }) if study_material_id
    query.first&.knowledge_node
  end

  # Find all possible concepts for a given term (including fuzzy matches)
  def self.find_possible_concepts(term, study_material_id = nil)
    normalized_term = term.downcase.strip
    query = active.joins(:knowledge_node)
                  .where('LOWER(concept_synonyms.synonym_name) LIKE ?', "%#{normalized_term}%")

    query = query.where(knowledge_nodes: { study_material_id: study_material_id }) if study_material_id

    query.distinct.pluck('knowledge_nodes.id', 'knowledge_nodes.name', 'concept_synonyms.similarity_score')
         .map { |id, name, score| { id: id, name: name, similarity_score: score } }
  end

  # Cluster synonyms by similarity
  def self.cluster_by_similarity(threshold: 0.8)
    high_similarity.group_by(&:knowledge_node_id)
  end

  def to_json_api
    {
      id: id,
      synonym_name: synonym_name,
      synonym_type: synonym_type,
      similarity_score: similarity_score,
      source: source,
      active: active,
      knowledge_node_name: knowledge_node.name,
      metadata: metadata
    }
  end
end
