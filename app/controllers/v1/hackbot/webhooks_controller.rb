module V1
  module Hackbot
    class WebhooksController < ApplicationController
      # Amount of time to delay HTTP responses to interactive message webhook
      # requests.
      #
      # 3 seconds is the max response delay before Slack retries the request.
      # While Slack is waiting for a response from our server, it displays a
      # loading icon in the Slack client to the user, so we want to wait as long
      # as possible before responding so it looks like Hackbot is doing
      # something while the user waits for their interaction to process.
      INTERACTIVE_MESSAGE_RESPONSE_DELAY = 2.5

      def interactive_messages
        start_time = Time.current

        payload = JSON.parse(params[:payload], symbolize_names: true)
        event = action_payload_to_event(payload)

        handle_event(event, event[:team_id])

        elapsed = Time.current - start_time
        to_wait = INTERACTIVE_MESSAGE_RESPONSE_DELAY - elapsed

        # If the processing of this request took less than
        # INTERACTIVE_MESSAGE_RESPONSE_DELAY to complete, sleep
        # INTERACTIVE_MESSAGE_RESPONSE_DELAY - amount of time it took to process
        # request before sending a response.
        sleep to_wait if to_wait > 0
      end

      def events
        case params[:type]
        when 'url_verification' # See https://api.slack.com/events/url_verification
          render plain: params[:challenge]
        when 'event_callback'
          render status: 200

          event = params[:event].to_unsafe_h

          handle_event(event, params[:team_id])
        else
          render status: :not_implemented
        end
      end

      def slash_command
        return if params[:ssl_check] == '1'

        event = slash_command_payload_to_event(params)

        handle_event(event, event[:team_id])
      end

      private

      def handle_event(event, team_id)
        # Slack HTML escapes the '>', '<', and '&' characters. This unescapes
        # them.
        event[:text] = CGI.unescapeHTML(event[:text]) if event[:text]

        HandleSlackEventJob.perform_later(event, team_id)
      end

      def action_payload_to_event(payload)
        { type: 'action',
          channel: payload[:channel][:id],
          team_id: payload[:team][:id],
          user: payload[:user][:id],
          ts: payload[:action_ts],
          action: resolve_action(payload[:actions].first,
                                 payload[:original_message][:attachments]),
          msg: payload[:original_message],
          response_url: payload[:response_url] }
      end

      # Given an action from payload[:actions], find its corresponding source
      # action in a list of Slack attachments.
      #
      # Actions in payload[:actions] don't have all of the attributes that their
      # source actions have, including the action text.
      def resolve_action(action, attachments)
        attachments.each do |attachment|
          next unless attachment[:actions].is_a? Enumerable

          attachment[:actions].each do |a|
            return a if a[:name] == action[:name] &&
                        a[:type] == action[:type] &&
                        a[:value] == action[:value]
          end
        end
      end

      # Note: this introduces a new subtype of message called "slash_command".
      #
      # This isn't part of Slack's API and only exists in the Hackbot realm for
      # our convenience.
      def slash_command_payload_to_event(payload)
        {
          type: 'message',
          subtype: 'slash_command',
          user: payload[:user_id],
          text: payload[:text],
          channel: payload[:channel_id],
          team_id: payload[:team_id],
          response_url: payload[:response_url]
        }
      end
    end
  end
end
