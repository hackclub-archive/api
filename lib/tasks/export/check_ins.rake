class Record
  attr_accessor :created_at, :meeting_date, :club_name, :leaders, :attendance,
                :notes

  def initialize(created_at, meeting_date, club_name, leaders, attendance,
                 notes)
    @created_at = created_at
    @meeting_date = meeting_date
    @club_name = club_name
    @leaders = leaders
    @attendance = attendance
    @notes = notes
  end

  # The titles of the fields that are getting put in the CSV.
  # This should be generated at runtime.
  def self.csv_title
    %w(created_at meeting_date club_name leaders attendance notes)
  end

  def csv_contents
    [created_at, meeting_date, club_name, leaders, attendance, notes]
  end
end

desc 'Generate a report of all check ins'
task check_ins: :environment do
  csv_string = CSV.generate do |csv|
    csv << Record.csv_title
    ::CheckIn.all.each do |check_in|
      r = Record.new(
        check_in.created_at,
        check_in.meeting_date,
        check_in.club.name,
        check_in.club.leaders.all.map(&:name).uniq,
        check_in.attendance,
        check_in.notes
      )

      csv << r.csv_contents
    end
  end

  puts csv_string
end