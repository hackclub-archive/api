# coding: utf-8

# A few Rubocop cops are disabled in this file because it's pending a refactor.
# See https://github.com/hackclub/api/issues/25.
module Hackbot
  module Conversations
    # rubocop:disable Metrics/ClassLength
    class CheckIn < Hackbot::Conversations::Channel
      def self.should_start?(event, _team)
        event[:text] == 'check in'
      end

      def start(event)
        info = leader(event)
        data['slack_username'] = info.slack_username

        first_name = info.name.split(' ').first

        msg_channel "Hey #{first_name}! Did you have a club meeting this week?"

        :wait_for_meeting_confirmation
      end

      # rubocop:disable Metrics/MethodLength
      def wait_for_meeting_confirmation(event)
        prompt_reply

        case event[:text]
        when /(yes|yeah|yup|mmhm|affirmative)/i
          msg_channel 'Okay, sweet! On which day was it? (say something '\
                      'like "monday" or "today")'

          :wait_for_day_of_week
        when /(no|nope|nah|negative)/i
          msg_channel 'Gotcha! Hope you have a great weekend.'

          :finish
        else
          msg_channel "I'm not very smart yet and had trouble understanding "\
                      'you :-/. Try saying something like "yes" or "no".'

          :wait_for_meeting_confirmation
        end
      end
      # rubocop:enable Metrics/MethodLength

      # rubocop:disable Metrics/MethodLength
      def wait_for_day_of_week(event)
        prompt_reply

        meeting_date = Chronic.parse(event[:text], context: :past)

        unless meeting_date
          msg_channel "Man, I'm not very smart yet and had trouble "\
                      'understanding you. Try saying something simpler, like '\
                      '"tuesday" or "thursday".'

          return :wait_for_day_of_week
        end

        unless meeting_date > 7.days.ago && meeting_date < Date.tomorrow
          msg_channel "Hmm, #{meeting_date.to_date} didn't happen in the past "\
                      'week (though I may also be misunderstanding you). Can '\
                      'you try giving me the day of the week of your last '\
                      'meeting again?'

          return :wait_for_day_of_week
        end

        data['meeting_date'] = meeting_date

        msg_channel "How many people would you estimate came? (I'm not very "\
                    "smart, I'll need you to give me a single number, "\
                    'something like "25" – give your best estimate)'

        :wait_for_attendance
      end
      # rubocop:enable Metrics/MethodLength

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
      def wait_for_attendance(event)
        prompt_reply

        unless integer?(event[:text])
          msg_channel "I didn't quite understand that. Can you try giving me "\
                      'a single number?'

          return :wait_for_attendance
        end

        count = event[:text].to_i

        if count < 0
          msg_channel "I'm going to need a positive number, silly. How many "\
                      'people came to the last meeting?'

          return :wait_for_attendance
        end

        data['attendance'] = count

        judgement = case count
                    when 0..9
                      'Nice!'
                    when 10..20
                      "#{count} is a number to be proud of!"
                    when 20..40
                      "Damn, #{count} is a huge number of people!"
                    when 40..100
                      "I have no words. #{count} people is incredible!"
                    else
                      "I'm speechless. That's incredible."
                    end

        msg_channel "#{judgement} Is there anything the Hack Club team can be "\
                    "helpful with? I'll send them anything you send my way "\
                    '(just make sure to include everything in a single '\
                    'message).'

        :wait_for_notes
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

      def wait_for_notes(event)
        prompt_reply

        data['notes'] = event[:text] unless event[:text] =~ /^(no|nope|nah)$/i

        ::CheckIn.create!(
          club: club(event),
          leader: leader(event),
          meeting_date: data['meeting_date'],
          attendance: data['attendance'],
          notes: data['notes']
        )

        msg_channel "Sweet, I'll let them know! Hope you have a hack-tastic "\
                    'weekend!'
      end

      def handle(event)
        data['last_message_ts'] = time

        super
      end

      DEFAULT_PROMPT_WAIT_TIME = 10.seconds

      def prompt_reply
        prompt_reply_in DEFAULT_PROMPT_WAIT_TIME
      end

      def prompt_reply_in(amount)
        SlackPromptReplyJob.set(wait: amount).perform_later(data['slack_username'], id, time)
      end

      private

      def integer?(str)
        Integer(str) && true
      rescue ArgumentError
        false
      end

      def club(event)
        @leader ||= leader(event)

        @leader.clubs.first
      end

      def leader(event)
        @u ||= user(event)
        @leader ||= Leader.find_by(slack_username: @u[:name])

        @leader
      end

      def user(event)
        user_id = event[:user]

        resp = SlackClient::Users.info(user_id, access_token)

        resp[:user]
      end

      def time
        Time.now.to_i
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
