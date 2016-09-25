class CreateStreakPipelines < ActiveRecord::Migration[5.0]
  def change
    create_table :streak_pipelines do |t|
      t.text :streak_key
      t.text :name

      t.timestamps
    end
  end
end
