FactoryBot.define do
  factory :concept_synonym do
    association :knowledge_node
    sequence(:synonym_name) { |n| "Synonym #{n}" }
    synonym_type { 'synonym' }
    similarity_score { 0.9 }
    source { 'manual' }
    active { true }
    metadata { {} }
  end
end
