FactoryBot.define do
  factory :knowledge_node do
    study_material
    sequence(:name) { |n| "Concept #{n}" }
    level { 'concept' }
    description { "Description for #{name}" }
    difficulty { rand(1..5) }
    importance { rand(1..5) }
    active { true }

    trait :subject do
      level { 'subject' }
      sequence(:name) { |n| "Subject #{n}" }
    end

    trait :chapter do
      level { 'chapter' }
      sequence(:name) { |n| "Chapter #{n}" }
    end

    trait :detail do
      level { 'detail' }
      sequence(:name) { |n| "Detail #{n}" }
    end
  end
end
