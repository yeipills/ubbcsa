FactoryBot.define do
  factory :quiz_result do
    quiz { nil }
    user { nil }
    attempt { nil }
    score { "9.99" }
    total_questions { 1 }
    correct_answers { 1 }
    time_spent { 1 }
  end
end
