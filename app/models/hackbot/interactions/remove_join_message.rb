module Hackbot
  module Interactions
    class RemoveJoinMessage < TextConversation
      def should_start?
        super && event[:subtype] == 'channel_join'
      end

      def start
        del_msg(event[:channel], event[:ts])
      end
    end
  end
end
