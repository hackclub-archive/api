module Hackbot
  module Interactions
    class Dormant < AdminCommand
      include Concerns::LeaderAssociable

      TRIGGER = /set-club dormant ?(?<subject_identifier>.+)/

      USAGE = 'set-club <dormant|active> <club_streak_key>'.freeze
      DESCRIPTION = 'pause check-ins for a club during summer break'.freeze

      DORMANT_STAGE_KEY = '5014'.freeze

      def start
        streak_key = captured[:subject_identifier]

        @club = Club.find_by(streak_key: streak_key)
        not_found && return unless @club

        @club.stage_key = DORMANT_STAGE_KEY
        StreakClient::Box.update(streak_key, 'stageKey' => DORMANT_STAGE_KEY)
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
