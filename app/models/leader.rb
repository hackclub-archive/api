class Leader < ApplicationRecord
  include Streakable
  include Geocodeable

  streak_pipeline_key Rails.application.secrets.streak_leader_pipeline_key
  streak_default_field_mappings key: :streak_key, name: :name, notes: :notes,
                                stage: :stage_key
  streak_field_mappings(
    email: '1003',
    gender: {
      key: '1001',
      type: 'DROPDOWN',
      options: {
        'Male' => '9001',
        'Female' => '9002',
        'Other' => '9003'
      }
    },
    year: {
      key: '1002',
      type: 'DROPDOWN',
      options: {
        '2016' => '9010',
        '2017' => '9004',
        '2018' => '9003',
        '2019' => '9002',
        '2020' => '9001',
        '2021' => '9006',
        '2022' => '9009',
        'Graduated' => '9005',
        'Teacher' => '9008',
        'Unknown' => '9007'
      }
    },
    phone_number: '1010',
    slack_username: '1006',
    github_username: '1009',
    twitter_username: '1008',
    address: '1011',
    latitude: '1018',
    longitude: '1019',
    slack_id: '1020'
  )

  geocode_attrs address: :address,
                latitude: :latitude,
                longitude: :longitude

  before_validation :slack_update

  has_many :check_ins
  has_and_belongs_to_many :clubs

  before_destroy do
    # Remove the club leader as the point of contact from any clubs they're
    # associated with.
    Club
      .where(point_of_contact_id: id)
      .find_each { |c| c.update(point_of_contact: nil) }
  end

  validates :name, presence: true
  validate :validate_slack_username_found

  def slack_update
    return if access_token.nil?

    if slack_id_changed?
      slack_id_sync
    elsif slack_username_changed?
      slack_username_sync
    end
  end

  def timezone
    Timezone.lookup(latitude, longitude)
  rescue Timezone::Error::InvalidZone
    Rails.logger.warn("Unable to find timezone for leader \##{id}")
    nil
  end

  private

  def validate_slack_username_found
    return unless user_from_username(slack_username).nil?
    errors.add(:slack_username, 'Slack user not found')
  end

  def slack_id_sync
    info = SlackClient::Users.info(slack_id, access_token)[:user]
    self.slack_username = info[:name] unless info.nil?
  end

  def slack_username_sync
    user = user_from_username slack_username
    self.slack_id = user[:id] unless user.nil?
  end

  def user_from_username(username)
    @all_users ||= SlackClient::Users.list(access_token)[:members]

    @all_users.find { |u| u[:name] == username }
  end

  def access_token
    return nil if team.nil?

    team.bot_access_token
  end

  def team
    Hackbot::Team.find_by(team_id: slack_team_id)
  end
end
