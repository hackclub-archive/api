# 1. Checks if a message has been sent since the job was queued
# 2. If it has, kill the job. If not then continue
# 3. Send a message prompting a response from the userc:w
# 4. Queue the job again (Back to step 1.)

class SlackPromptReplyJob < ApplicationJob
  queue_as :default

  HACK_CLUB_TEAM_ID = 'T0266FRGM'.freeze

  MESSAGE_PROMPT_TEXT = "LISTEN HERE LADDY/LADDESS. YOU SIR/MA'AM ARE G'NNA RESPOND TO THIS HERE SL'CK MESSAGE."

  def perform(username, conversation_id, job_queued_time)
    convo = Hackbot::Conversations::CheckIn.find(conversation_id)

    if convo.data['last_message_ts'] > job_queued_time 
      puts 'Message has been replied to in an adequate amount of time'
      return
    end

    byebug

    user = user_from_username(username)

    SlackClient.rpc('chat.postMessage', access_token, {
      channel: user[:id],
      text: MESSAGE_PROMPT_TEXT,
      as_user: true
    })
  end

  private

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
