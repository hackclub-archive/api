module Hackbot
  module Conversations
    class Define < Hackbot::Conversations::Channel
      def self.should_start?(event, team)
        event[:text].include?('define') && mentions_name?(event, team)
      end

      def start(event)
        query = event_to_query event
        if query.empty?
          msg_channel "You didn't tell me what to define!"
          return :finish
        end
        response = UrbanDictionaryClient.define query
        msg_channel response
      end

      private

      def event_to_query(event)
        event[:text]
          .sub(team[:bot_username], '')
          .sub("<@#{team[:bot_user_id]}>", '')
          .sub('define', '').strip
      end
    end
  end
end
