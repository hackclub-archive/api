class AddSlackIdToLeader < ActiveRecord::Migration[5.0]
  def change
    add_column :leaders, :slack_id, :text
    reversible do |change|
      # Populate fields with slack usernames
      change.up do
        populate_slack_ids!
      end
    end
  end

  def populate_slack_ids!
    access_token = Hackbot::Team.first.bot_access_token

    leaders = select_all 'SELECT * FROM leaders '\
                         'WHERE slack_username IS NOT NULL AND '\
                         "slack_username != ''"

    leaders.each do |leader|
      @all_users ||= SlackClient::Users.list(access_token)[:members]

      slack_user = @all_users.find { |u| u[:name] == leader['slack_username'] }
      update "UPDATE leaders SET slack_id = '#{slack_user[:id]}' "\
             "WHERE slack_username = '#{leader['slack_username']}'"
    end
  end
end
