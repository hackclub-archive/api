module Hackbot
  module Conversations
    class Followupable < Hackbot::Conversations::Channel
      DEFAULT_PROMPT_DELAY = 10.seconds
      DEFAULT_PROMPT_TEXT = 'Ping! Would you mind responding to my previous'\
        'message?'.freeze

      def handle(event)
        if data['slack_id'].nil?
          data['slack_id'] = event[:user]
        else
          data['last_message_ts'] = timestamp
          data['last_message'] = event[:text]
        end

        super(event)
      end


      def prompt_reply(message=DEFAULT_PROMPT_TEXT, amount=DEFAULT_PROMPT_DELAY)
        SlackPromptReplyJob.set(
          wait: amount
        ).perform_later(
          message,
          data['slack_id'],
          id,
          timestamp)
      end

      def prompt_reply_in(amount)
        prompt_reply(DEFAULT_PROMPT_TEXT, DEFAULT_PROMPT_DELAY)
      end

      private

      def timestamp
        Time.now.iso8601(10)
      end
    end
  end
end
