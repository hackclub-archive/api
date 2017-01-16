module Hackbot
  module Conversations
    class Game < Hackbot::Conversations::Channel
      def self.should_start?(event)
        event[:text] == 'game'
      end

      BOARD_WIDTH = 20
      BOARD_HEIGHT = 20

      def start(event)
        self.board = Array.new(BOARD_HEIGHT) { Array.new(BOARD_WIDTH) }
        self.player = {'x' => BOARD_WIDTH/2, 'y' => BOARD_WIDTH/2}
        self.food = []

        resp = msg_channel render(0)
        self.data['message_ts'] = resp[:message][:ts]

        :game_loop
      end

      def game_loop(event)
        return :finish if event[:type] == 'message' && event[:text] == 'please stop'

        dt = 0

        update(dt, event)
        to_send = render(dt)

        SlackClient.rpc('chat.update', access_token, ts: self.data['message_ts'], channel: self.data['channel'], text: to_send)

        :game_loop
      end

      private

      def update(dt, event)
        return unless event[:type] == 'message'

        case event[:text]
        when 'up'
          player['y'] -= 1
        when 'down'
          player['y'] += 1
        when 'left'
          player['x'] -= 1
        when 'right'
          player['x'] += 1
        end

        self.player = player
      end

      def render(dt)
        output = board.map { |r| r.map { |c| c.nil? ? '👻' : c } }

        output[player['y']][player['x']] = '🤔'

        str = output.map { |r| r.join }.join "\n"

        '```'+"\n"+str+"\n"+'```'
      end

      def board
        self.data['board']
      end

      def board=(new_board)
        self.data['board'] = new_board
      end

      def player
        self.data['player']
      end

      def player=(new_player)
        self.data['player'] = new_player
      end

      def food
        self.data['food']
      end

      def food=(new_food)
        self.data['food'] = new_food
      end
    end
  end
end
