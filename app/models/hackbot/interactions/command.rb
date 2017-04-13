module Hackbot
  module Interactions
    class Command < TextConversation
      def self.usage(event, team)
        new(event: event, team: team).usage
      end

      def self.description(event, team)
        new(event: event, team: team).description
      end

      def should_start?
        # We have to use self.class:: to access the constant because of the
        # quirk described in this StackOverflow question:
        #
        # http://stackoverflow.com/q/42779998/1001686
        trigger = self.class::TRIGGER
        matcher = nil

        if event[:subtype] == 'slash_command'
          matcher = /^#{trigger}$/
        else
          mention_regex = Hackbot::Utterances.name(team)
          matcher = /^#{mention_regex} #{trigger}$/
        end

        msg =~ matcher && super
      end

      def captured
        @_captured ||= self.class::TRIGGER.match(msg)
      end

      def usage
        self.class::USAGE if self.class.const_defined? 'USAGE'
      end

      def description
        self.class::DESCRIPTION if self.class.const_defined? 'DESCRIPTION'
      end

      def reply(msg)
        if event[:subtype] == 'slash_command'
          opts = {}

          if msg.is_a? String
            opts[:text] = msg
          else
            opts = msg
          end

          if opts[:attachments]
            opts[:attachments] = insert_attachment_defaults(opts[:attachments])
          end

          payload = { token: access_token, **opts }

          RestClient::Request.execute(
            method: :post,
            url: event[:response_url],
            payload: payload.to_json
          )
        else
          msg_channel(msg)
        end
      end

      def attach_reply(*attachments)
        reply(attachments: attachments)
      end
    end
  end
end
