require 'byebug'
module Hackbot
  module Conversations
    class SingleMessageCommand < Hackbot::Conversations::Channel
      def self.should_start?(event, team)
        @@team = team
        event[:type] == 'message' &&
          event_should_trigger_command?(event)
      end

      def self.set_command(command)
        @@command = command
      end

      def self.command_regex
        /^(#{@@team[:bot_username]}|<@#{@@team[:bot_user_id]}>) #{@@command}/
      end

      def self.event_should_trigger_command? event
        (/^(#{@@team[:bot_username]}|<@#{@@team[:bot_user_id]}>) #{@@command}/=~ event[:text]).nil?
      end

      def respond(query)
        raise NotImplementedError
      end

      def start(event)
        respond(event_to_query(event))
      end

      protected

      def event_to_query(event)
        event[:text].sub(command_regex, '').strip
      end
    end
  end
end
