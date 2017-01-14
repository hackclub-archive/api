class Cloud9Invite < ApplicationRecord
  validates :email, presence: true, uniqueness: true, email: true

  before_create :invite_member

  def invite_member
    Cloud9Client::Team.invite_member(
      Rails.application.secrets.cloud9_team_name,
      email
    )
  rescue RestClient::Conflict
    errors.add(:send_invite, "Couldn't invite member")
  end
end
