# coding: utf-8

# A few Rubocop cops are disabled in this file because it's pending a refactor.
# See https://github.com/hackclub/api/issues/25.

# I'm experimenting with a new naming convention here. Any method that expects
# only button callback events should be suffixed with `_press`.

module Hackbot
  module Interactions
    # rubocop:disable Metrics/ClassLength
    class CheckIn < TextConversation
      include Concerns::Followupable, Concerns::Triggerable

      TASK_ASSIGNEE = Rails.application.secrets.default_streak_task_assignee

      def should_start?
        false
      end

      def start
        first_name = leader.name.split(' ').first
        deadline = formatted_deadline leader
        key = 'greeting'
        buttons = [
          { text: 'Yes, my club met!', value: 'yes' },
          { text: 'No, my club did not meet', value: 'no' }
        ]

        # If this is their first check in, we'll give them a special greeting
        # message
        key = 'first_greeting' if first_check_in?

        # If they've had previous successful check ins we'll change the buttons
        # to include an option for meeting on the same day as the previous check
        # in
        if previous_check_in_day
          buttons = [
            { text: "Yes, on #{previous_check_in_day}",
              value: 'previous_day' },
            { text: 'Yes, on another day',
              value: 'yes' },
            { text: 'No', value: 'no' }
          ]
        end

        msg_channel(
          text: copy(key, first_name: first_name, deadline: deadline),
          attachments: [
            fallback: 'Choose yes or no',
            actions: buttons
          ]
        )

        default_follow_up 'wait_for_meeting_confirmation_press'
        :wait_for_meeting_confirmation_press
      end

      # rubocop:disable Metrics/MethodLength
      def wait_for_meeting_confirmation_press
        return unless action

        resp = case action[:value]
               when 'yes'
                 ":white_check_mark: *You had a meeting*"
               when 'previous_day'
                 ":white_check_mark: *You had a meeting on #{previous_check_in_day}*"
               when 'no'
                 ":no_entry_sign: *You did not have a meeting*"
               end
        update_action_source(**event[:msg], attachments: [text: resp])

        case action[:value]
        when 'yes'
          msg_channel copy('meeting_confirmation.positive')

          default_follow_up 'wait_for_day_of_week'
          :wait_for_day_of_week
        when 'previous_day'
          data['meeting_date'] = Chronic.parse(previous_check_in_day, context: :past)

          msg_channel copy('day_of_week.valid')

          default_follow_up 'wait_for_attendance'
          :wait_for_attendance
        when 'no'
          msg_channel copy('meeting_confirmation.negative')

          default_follow_up 'wait_for_no_meeting_reason'
          :wait_for_no_meeting_reason
        end
      end
      # rubocop:enable Metrics/MethodLength

      def wait_for_no_meeting_reason
        data['no_meeting_reason'] = msg

        if should_ask_if_dead?
          msg_channel(
            text: copy('no_meeting_reason'),
            attachments: [
              fallback: 'Choose yes or no',
              actions: [
                # TODO: Write these button messages better
                { text: 'Yep!',
                  value: 'yes' },
                { text: 'Nope', value: 'no' }
              ]
            ]
          )

          default_follow_up 'wait_for_meeting_in_the_future_press'
          :wait_for_meeting_in_the_future_press
        else
          msg_channel(
            text: copy('meeting_in_the_future.positive'),
            attachments: [
              fallback: 'Choose yes or no',
              actions: [
                { text: 'Yes', value: 'yes' },
                { text: 'No', value: 'no' }
              ]
            ]
          )

          default_follow_up 'wait_for_preventing_future_meetings_press'
          :wait_for_preventing_future_meetings_press
        end
      end

      # rubocop:disable Metrics/MethodLength
      def wait_for_meeting_in_the_future_press
        return unless action

        resp =  case action[:value]
                when 'yes'
                  ":white_check_mark: *You plan on meeting*"
                when 'no'
                  ":no_entry_sign: *Your club is no longer meeting*"
                end
        update_action_source(**event[:msg], attachments: [text: resp])

        case action[:value]
        when 'yes'
          msg_channel(
            text: copy('meeting_in_the_future.positive'),
            attachments: [
              fallback: 'Choose yes or no',
              actions: [
                { text: 'Yes', value: 'yes' },
                { text: 'No', value: 'no' }
              ]
            ]
          )

          default_follow_up 'wait_for_preventing_future_meetings_press'
          :wait_for_preventing_future_meetings_press
        when 'no'
          msg_channel copy('meeting_in_the_future.negative')
          data['wants_to_be_dead'] = true

          :finish
        end
      end
      # rubocop:enable Metrics/MethodLength

      def wait_for_preventing_future_meetings_press
        return unless action
        resp =  case action[:value]
                when 'yes'
                  ":no_entry_sign: *Something is preventing your club from meeting*"
                when 'no'
                  ":white_check_mark: *Nothing is preventing your club from meeting*"
                end
        update_action_source(**event[:msg], attachments: [text: resp])

        case action[:value]
        when 'no'

          msg_channel copy('help')
        when 'yes'
          msg_channel copy('meeting_prevent_reason')

          default_follow_up 'wait_for_help'
          :wait_for_help
        end
      end

      def wait_for_help
        if should_record_notes?
          notes = record_notes
          create_task leader, 'Follow-up on notes from a failed '\
            "meeting: #{notes}"
        end

        msg_channel copy('help')
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def wait_for_day_of_week
        meeting_date = Chronic.parse(msg, context: :past)

        unless meeting_date
          msg_channel copy('day_of_week.unknown')

          default_follow_up 'wait_for_day_of_week'
          return :wait_for_day_of_week
        end

        unless meeting_date > 7.days.ago && meeting_date < Date.tomorrow
          msg_channel copy('day_of_week.invalid')

          default_follow_up 'wait_for_day_of_week'
          return :wait_for_day_of_week
        end

        data['meeting_date'] = meeting_date

        msg_channel copy('day_of_week.valid')

        default_follow_up 'wait_for_attendance'
        :wait_for_attendance
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      # rubocop:disable Metrics/CyclomaticComplexity,
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def wait_for_attendance
        unless integer?(msg)
          msg_channel copy('attendance.invalid')

          default_follow_up 'wait_for_attendance'
          return :wait_for_attendance
        end

        count = msg.to_i

        if count < 0
          msg_channel copy('attendance.not_realistic')

          default_follow_up 'wait_for_attendance'
          return :wait_for_attendance
        end

        data['attendance'] = count

        judgement = case count
                    when 0..9
                      copy('judgement.ok', count: count)
                    when 10..20
                      copy('judgement.good', count: count)
                    when 20..40
                      copy('judgement.great', count: count)
                    when 40..100
                      copy('judgement.awesome', count: count)
                    else
                      copy('judgement.impossible')
                    end

        msg_channel copy('attendance.valid', judgement: judgement)

        default_follow_up 'wait_for_notes'
        :wait_for_notes
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/MethodLength

      # rubocop:disable Metrics/MethodLength
      def wait_for_notes
        if should_record_notes?
          notes = record_notes
          create_task leader, 'Follow-up on notes from check-in: '\
            "#{notes}"
        end

        generate_check_in

        if data['notes'].nil?
          msg_channel copy('notes.no_notes')
        else
          msg_channel copy('notes.had_notes')
        end

        send_attendance_stats
      end
      # rubocop:enable Metrics/MethodLength

      def generate_check_in
        ::CheckIn.create!(
          club: club,
          leader: leader,
          meeting_date: data['meeting_date'],
          attendance: data['attendance'],
          notes: data['notes']
        )
      end

      private

      def formatted_deadline(lead)
        timezone = lead.timezone || Timezone.fetch('America/Los_Angeles')
        date_format = '%A, %b %e at %l:%m %p'
        deadline_utc = DateTime.now.utc.next_week + 15.hours
        deadline_local = timezone.utc_to_local(deadline_utc)
        timezone_abbr = timezone.abbr(deadline_local)

        "#{deadline_local.strftime(date_format)} #{timezone_abbr}"
      end

      def default_follow_up(next_state)
        interval = 24.hours

        messages = [
          copy('follow_ups.first'),
          copy('follow_ups.second'),
          copy('follow_ups.third')
        ]

        follow_up(messages, next_state, interval)
      end

      def send_attendance_stats
        stats = statistics leader

        return if stats.total_meetings_count < 2

        graph = Charts.bar(
          stats.attendance,
          stats.labels
        )

        file_to_channel('attendance_this_week.png', Charts.as_file(graph))
      end

      def create_task(lead, text)
        StreakClient::Task.create(
          lead.streak_key,
          text,
          due_date: Time.zone.now.next_week(:monday),
          assignees: [TASK_ASSIGNEE]
        )
      end

      def statistics(leader)
        @stats ||= ::StatsService.new(leader)

        @stats
      end

      def should_record_notes?
        (msg =~ Hackbot::Utterances.no).nil?
      end

      def record_notes
        data['notes'] = msg
      end

      def should_ask_if_dead?
        Hackbot::Interactions::CheckIn
          .where("data->>'channel' = '#{data['channel']}'")
          .order('created_at DESC')
          .limit(3)
          .map { |c| c.data['attendance'].nil? }
          .reduce(:&)
      end

      def first_check_in?
        CheckIn.where("data->>'channel' = ?", data['channel']).empty?
      end

      def previous_check_in_day
        # TODO: Support other previous days check-in days
        Date::DAYNAMES[Date.parse('Tuesday').wday]
      end

      def integer?(str)
        Integer(str) && true
      rescue ArgumentError
        false
      end

      def club
        leader.clubs.first
      end

      def leader
        pipeline_key = Rails.application.secrets.streak_leader_pipeline_key
        slack_id_field = :'1020'

        @leader_box ||= StreakClient::Box
                        .all_in_pipeline(pipeline_key)
                        .find { |b| b[:fields][slack_id_field] == event[:user] }

        @leader ||= Leader.find_by(streak_key: @leader_box[:key])
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
