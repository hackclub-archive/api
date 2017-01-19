# 1. Checks if a message has been sent since the job was queued
# 2. If it has, kill the job. If not then continue
# 3. Send a message prompting a response from the user
# 4. Queue the job again (Back to step 1.)

class SlackPromptReplyJob < ApplicationJob
  queue_as :default

  HACK_CLUB_TEAM_ID = 'T0266FRGM'.freeze

  MESSAGE_PROMPT_TEXT = 'Ping! Would you mind responding to my previous'\
    'message?'.freeze

  def perform(slack_id, conversation_id, job_queued_time)
    convo = Hackbot::Conversations::CheckIn.find(conversation_id)

    if convo.data['last_message_ts'].nil?
      send_prompt slack_id
    elsif convo.data['last_message_ts'].to_time < job_queued_time.to_time
      send_prompt slack_id
    end
  end

  private

  def send_prompt(slack_id)
    SlackClient.rpc('chat.postMessage',
                    access_token,
                    channel: slack_id,
                    text: MESSAGE_PROMPT_TEXT,
                    as_user: true)
  end

  # This constructs a fake Slack event to start the conversation with. It'll be
  # sent to the conversation's start method.
  #
  # This is clearly a hack and our conversation class should be refactored to
  # account for this use case.
  def construct_fake_event(user, channel_id)
    {
      team_id: slack_team.team_id,
      user: user[:id],
      type: 'message',
      channel: channel_id
    }
  end

  def open_im(user)
    SlackClient::Chat.open_im(user[:id], access_token)
  end

  def user_from_username(username)
    @all_users ||= SlackClient::Users.list(access_token)[:members]

    @all_users.find { |u| u[:name] == username }
  end

  def access_token
    slack_team.bot_access_token
  end

  def slack_team
    Hackbot::Team.find_by(team_id: HACK_CLUB_TEAM_ID)
  end
end
