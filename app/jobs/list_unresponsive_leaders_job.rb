# Lists all of the leaders who have not responded to Hackbot's CheckIn task
class ListUnresponsiveLeadersJob < ApplicationJob
  queue_as :default

  HACK_CLUB_TEAM_ID = 'T0266FRGM'.freeze

  def perform(*)
    users = Hackbot::Conversations::CheckIn.where.not(state: 'finish').where('created_at > ?', 2.days.ago)

    to_follow_up_with = users.map do |c|
      SlackClient::Users.info(dm_to_user(c.data['channel']), c.team.bot_access_token)
    end

    usernames = to_follow_up_with.map { |u| u[:user][:name] }
    usernames = usernames.uniq

    usernames.each { |u| puts u }
  end

  private

  def channels
    SlackClient.rpc('im.list', access_token)[:ims]
  end

  def dm_to_user(dm_id)
    us = channels.select { |im| im[:id] == dm_id}
    us.length > 0 ? us.first[:user] : nil
  end

  def access_token
    slack_team.bot_access_token
  end

  def slack_team
    Hackbot::Team.find_by(team_id: HACK_CLUB_TEAM_ID)
  end
end
