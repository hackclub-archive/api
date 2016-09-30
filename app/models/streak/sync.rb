class Streak::Sync < ApplicationRecord
  belongs_to :pipeline, class_name: Streak::Pipeline, foreign_key: "streak_pipeline_id"

  validates_presence_of :pipeline, :dest_table
  validates_uniqueness_of :dest_table, scope: :streak_pipeline_id
end
