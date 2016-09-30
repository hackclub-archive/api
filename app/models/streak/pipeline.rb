class Streak::Pipeline < ApplicationRecord
  has_many :fields, class_name: Streak::Field, foreign_key: "streak_pipeline_id"

  validates_presence_of :streak_key, :name
  validates_uniqueness_of :streak_key
end
