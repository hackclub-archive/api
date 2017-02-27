module Hackbot
  module Conversations
    class Gifs < Hackbot::Conversations::SingleMessageCommand
      set_command 'gif'

      def respond(query)
        if query.empty?
          msg_channel 'You need to provide a query, silly!'

          return :finish
        end

        gif = GiphyClient.translate query

        send_gif('A gif from Giphy!', gif[:url])
      end

      private

      def send_gif(text, url)
        SlackClient.rpc('chat.postMessage',
                        access_token,
                        channel: data['channel'],
                        as_user: true,
                        attachments: [
                          {
                            text: text,
                            image_url: url
                          }
                        ].to_json)
      end
    end
  end
end
