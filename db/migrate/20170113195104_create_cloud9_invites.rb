class CreateCloud9Invites < ActiveRecord::Migration[5.0]
  def change
    create_table :cloud9_invites do |t|
      t.text :email

      t.timestamps
    end
  end
end
