class Streak::Field < ApplicationRecord
  belongs_to :pipeline, class_name: Streak::Pipeline, foreign_key: "streak_pipeline_id"

  validates_presence_of :streak_key, :pipeline, :name, :field_type
  validates_uniqueness_of :streak_key, scope: :streak_pipeline_id
end
