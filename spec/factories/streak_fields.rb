FactoryGirl.define do
  factory :streak_field, class: Streak::Field do
    streak_key { rand.to_s[2..5] } # Random 4 digit number
    association :pipeline, factory: :streak_pipeline
    name { Faker::Lorem.word.titleize }
    field_type { Faker::Lorem.word.titleize }
  end
end
