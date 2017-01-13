class Cloud9Invite < ApplicationRecord
  validates :email, presence: true
  validates :email, uniqueness: true
  validates :email, email: true

  before_create :invite_member

  def invite_member
    Cloud9Client::Team.invite_member(
      Rails.application.secrets.cloud9_team_name,
      email
    )
  rescue
    errors.add(:invite_member_error, 'Couldn\'t invite member')
  end
end
