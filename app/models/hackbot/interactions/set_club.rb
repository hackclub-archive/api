module Hackbot
  module Interactions
    class SetClub < Command
      include Concerns::LeaderAssociable

      TRIGGER = /set-club *(?<args>.*)/

      USAGE = 'set-club <dormant|active> <club_streak_key (admin only)>'.freeze
      DESCRIPTION = 'pause check-ins for your club during summer break'.freeze

      STAGES = {
        'active' => '5003',
        'dormant' => '5014'
      }.freeze

      def should_handle?
        if state == 'wait_for_club_select'
          super && event[:user] == data['slack_id']
        else
          super
        end
      end

      # rubocop:disable Metrics/AbcSize
      def start
        arr = captured[:args].split(' ')

        data['stage_name'] = arr.first.downcase
        data['stage_key'] = STAGES[data['stage_name']]
        data['streak_key'] = arr.second
        data['slack_id'] = event[:user]

        invalid_stage && return unless data['stage_key']

        data['streak_key'] ? admin_run : leader_run
      end
      # rubocop:enable Metrics/AbcSize

      private

      def admin_run
        data['club'] = Club.find_by(streak_key: data['streak_key'])
        not_found if data['club'].nil?
        set_single_club
      end

      def leader_run
        case leader.clubs.count
        when 0
          msg_channel copy('no_clubs_found')
        when 1
          data['club'] = leader.clubs.first
          set_single_club
        else
          set_one_in_many_clubs
        end
      end

      def set_one_in_many_clubs
        actions = []
        leader.clubs.each { |c| actions << { text: c.name, value: c.id } }
        msg_channel(
          text: copy('many_clubs.prompt', stage_name: data['stage_name']),
          attachments: [
            actions: actions
          ]
        )
        :wait_for_club_select
      end

      def wait_for_club_select
        return :wait_for_club_select unless action

        data['club'] = Club.find action[:value]

        send_action_result copy('many_clubs.action_result',
                                club_name: data['club'].name)

        set_single_club
      end

      # rubocop:disable Metrics/AbcSize
      def set_single_club
        if data['club'].stage_key == data['stage_key']
          already_in_stage
        else
          data['club'].stage_key = data['stage_key']
          data['club'].save

          stage_changed
        end
        :finish
      end
      # rubocop:enable Metrics/AbcSize

      def stage_changed
        reaction = copy("reaction.#{data['stage_name']}") ||
                   copy('reaction.else')
        msg_channel copy('stage_changed', name: data['club'].name,
                                          stage_name: data['stage_name'],
                                          reaction: reaction)
      end

      def already_in_stage
        msg_channel copy('already_in_stage',
                         stage_name: data['club'].stage_name)
      end

      def not_found
        msg_channel copy('not_found')
      end

      def invalid_stage
        msg_channel copy('invalid_stage')
      end
    end
  end
end
