# Channel is a conversation that is limited to a single channel on Slack. Most
# conversations will inherit from this class.
module Hackbot
  module Conversations
    class Channel < Hackbot::Conversation
      def part_of_convo?(event)
        event[:channel] == data['channel'] && super
      end

      def handle(event)
        data['channel'] = event[:channel]
        super
      end

      protected

      def msg_channel(text)
        send_msg(data['channel'], text)
      end

      def file_to_channel(filename, file)
        send_file(data['channel'], filename, file)
      end
    end
  end
end
