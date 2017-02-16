class MainPointOfContact < ApplicationRecord
  validates :leader, presence: true
  validates :club, presence: true

  belongs_to :leader
  belongs_to :club
end
