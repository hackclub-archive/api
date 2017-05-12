module Hackbot
  module Interactions
    class SetClub < Command
      include Concerns::LeaderAssociable

      TRIGGER = /set-club ?(?<stage_name>.+)/

      USAGE = 'set-club <dormant|active>'.freeze
      DESCRIPTION = 'pause check-ins for your club during summer break'.freeze

      STAGES = %w(active dormant).freeze

      def should_handle?
        super && event[:user] == data['slack_id'] unless state == 'start'
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def start
        data['stage_name'] = captured[:stage_name]
        data['slack_id'] = event[:user]

        invalid_stage && return unless STAGES.include? data['stage_name']

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
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      def wait_for_club_select
        return :wait_for_club_select unless action

        data['club'] = Club.find action[:value]

        send_action_result copy('many_clubs.action_result',
                                club_name: data['club'].name)

        set_single_club
      end

      # rubocop:disable Metrics/AbcSize
      def wait_for_activation_date
        return :wait_for_activation_date unless msg

        data['activation_date'] = Chronic.parse(msg, bias: :future)
        human_date = data['activation_date']
                     .to_date
                     .to_formatted_s :long_ordinal
        msg_channel copy('activation_date.confirmation',
                         activation_date: human_date)

        Club.find(data['club']['id']).make_dormant(data['activation_date'])

        :finish
      end
      # rubocop:enable Metrics/AbcSize

      private

      def set_one_in_many_clubs
        actions = leader.clubs.map { |c| { text: c.name, value: c.id } }

        msg_channel(
          text: copy('many_clubs.prompt', stage_name: data['stage_name']),
          attachments: [
            actions: actions
          ]
        )

        :wait_for_club_select
      end

      def set_single_club
        case data['stage_name']
        when data['club'].stage_name
          already_in_stage
        when 'active'
          data['club'].make_active
          stage_changed
        when 'dormant'
          msg_channel copy('activation_date.prompt')
          :wait_for_activation_date
        end
      end

      def stage_changed
        reaction = copy("reaction.#{data['stage_name']}") ||
                   copy('reaction.else')
        msg_channel copy('stage_changed', name: data['club'].name,
                                          stage_name: data['stage_name'],
                                          reaction: reaction)

        :finish
      end

      def already_in_stage
        msg_channel copy('already_in_stage',
                         stage_name: data['club'].stage_name)
        :finish
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
