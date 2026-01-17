FactoryBot.define do
  factory :question_concept do
    association :question
    association :knowledge_node
    importance_level { 5 }
    relevance_score { 0.7 }
    is_primary_concept { false }
    extraction_method { 'ai' }
    metadata { {} }
  end
end
