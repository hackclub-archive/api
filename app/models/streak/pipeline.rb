class Streak::Pipeline < ApplicationRecord
  validates_presence_of :streak_key, :name
  validates_uniqueness_of :streak_key
end
