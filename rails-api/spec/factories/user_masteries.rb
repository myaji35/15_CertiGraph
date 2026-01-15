FactoryBot.define do
  factory :user_mastery do
    user
    knowledge_node
    mastery_level { 0.5 }
    status { 'learning' }
    color { 'yellow' }
    attempts { 5 }
    correct_attempts { 3 }
    total_time_minutes { 30 }
    last_tested_at { Time.current }

    trait :mastered do
      mastery_level { 0.95 }
      status { 'mastered' }
      color { 'green' }
      attempts { 20 }
      correct_attempts { 19 }
      total_time_minutes { 120 }
    end

    trait :weak do
      mastery_level { 0.2 }
      status { 'weak' }
      color { 'red' }
      attempts { 10 }
      correct_attempts { 2 }
      total_time_minutes { 60 }
    end

    trait :untested do
      mastery_level { 0.0 }
      status { 'untested' }
      color { 'gray' }
      attempts { 0 }
      correct_attempts { 0 }
      total_time_minutes { 0 }
      last_tested_at { nil }
    end
  end
end
