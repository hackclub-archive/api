# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160930174612) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "clubs", force: :cascade do |t|
    t.text     "name"
    t.text     "address"
    t.decimal  "latitude"
    t.decimal  "longitude"
    t.text     "source"
    t.text     "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "streak_fields", force: :cascade do |t|
    t.integer  "streak_key"
    t.integer  "streak_pipeline_id"
    t.text     "name"
    t.text     "field_type"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["streak_pipeline_id"], name: "index_streak_fields_on_streak_pipeline_id", using: :btree
  end

  create_table "streak_pipelines", force: :cascade do |t|
    t.text     "streak_key"
    t.text     "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "streak_syncs", force: :cascade do |t|
    t.integer  "streak_pipeline_id"
    t.text     "dest_table"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["streak_pipeline_id"], name: "index_streak_syncs_on_streak_pipeline_id", using: :btree
  end

  add_foreign_key "streak_fields", "streak_pipelines"
  add_foreign_key "streak_syncs", "streak_pipelines"
end
