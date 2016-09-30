FactoryGirl.define do
  factory :streak_pipeline, class: Streak::Pipeline do
    streak_key { Faker::Lorem.characters(70) }
    name { Faker::Lorem.words(4).join(" ").titlecase }

    factory :streak_pipeline_with_fields do
      transient do
        fields_count 5
      end

      after(:create) do |pipeline, evaluator|
        create_list(:streak_field, evaluator.fields_count, pipeline: pipeline)
      end
    end
  end
end
