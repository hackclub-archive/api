module Hackbot
  module Interactions
    class Active < AdminCommand
      include Concerns::LeaderAssociable

      TRIGGER = /set-club active ?(?<subject_identifier>.+)/

      USAGE = 'set-club active <club_streak_key>'.freeze
      DESCRIPTION = 'turn on weekly check-ins'.freeze

      ACTIVE_STAGE_KEY = '5003'.freeze

      def start
        streak_key = captured[:subject_identifier]

        @club = Club.find_by(streak_key: streak_key)
        not_found && return unless @club

        @club.stage_key = ACTIVE_STAGE_KEY
        StreakClient::Box.update(streak_key, 'stageKey' => ACTIVE_STAGE_KEY)
        stage_changed if @club.save
      end

      private

      def not_found
        msg_channel copy('not_found')
      end

      def stage_changed
        msg_channel copy('stage_changed', club_name: @club.name)
      end
    end
  end
end
