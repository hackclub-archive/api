class AddFailedToHappenToCheckIn < ActiveRecord::Migration[5.0]
  def change
    add_column :check_ins, :failed_to_happen, :text
  end
end
