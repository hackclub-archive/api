class CreateStreakFields < ActiveRecord::Migration[5.0]
  def change
    create_table :streak_fields do |t|
      t.integer :streak_key
      t.references :streak_pipeline, foreign_key: true
      t.text :name
      t.text :field_type

      t.timestamps
    end
  end
end
