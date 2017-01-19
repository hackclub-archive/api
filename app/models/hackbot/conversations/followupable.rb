module Hackbot
  module Conversations
    class Followupable < Hackbot::Conversations::Channel
      def handle(event)
        if data['slack_id'].nil?
          data['slack_id'] = event[:user]
        else
          data['last_message_ts'] = timestamp
          data['last_message'] = event[:text]
        end

        super(event)
      end

      DEFAULT_PROMPT_WAIT_TIME = 10.seconds

      def prompt_reply
        prompt_reply_in DEFAULT_PROMPT_WAIT_TIME
      end

      def prompt_reply_in(amount)
        SlackPromptReplyJob.set(wait: amount).perform_later(data['slack_id'], id, timestamp)
      end

      private

      def timestamp
        Time.now.iso8601(10)
      end
    end
  end
end
