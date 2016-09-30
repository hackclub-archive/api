FactoryGirl.define do
  factory :streak_sync, class: Streak::Sync do
    dest_table { ActiveRecord::Base.connection.tables.sample }
    association :pipeline, factory: :streak_pipeline
  end
end
