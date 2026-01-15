FactoryBot.define do
  factory :knowledge_edge do
    knowledge_node
    related_node { association :knowledge_node }
    relationship_type { 'prerequisite' }
    weight { 0.8 }
    reasoning { 'Test relationship' }
    active { true }

    trait :prerequisite do
      relationship_type { 'prerequisite' }
      weight { 0.8 }
    end

    trait :related do
      relationship_type { 'related_to' }
      weight { 0.6 }
    end

    trait :part_of do
      relationship_type { 'part_of' }
      weight { 0.9 }
    end

    trait :example do
      relationship_type { 'example_of' }
      weight { 0.5 }
    end

    trait :leads_to do
      relationship_type { 'leads_to' }
      weight { 0.7 }
    end
  end
end
