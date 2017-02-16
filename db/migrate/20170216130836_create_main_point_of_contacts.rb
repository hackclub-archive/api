class CreateMainPointOfContacts < ActiveRecord::Migration[5.0]
  def change
    create_table :main_point_of_contacts do |t|
      t.references :club, foreign_key: true
      t.references :leader, foreign_key: true

      t.timestamps
    end
  end
end
