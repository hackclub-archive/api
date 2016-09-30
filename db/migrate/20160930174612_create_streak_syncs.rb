class CreateStreakSyncs < ActiveRecord::Migration[5.0]
  def change
    create_table :streak_syncs do |t|
      t.references :streak_pipeline, foreign_key: true
      t.text :dest_table

      t.timestamps
    end
  end
end
