# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_10_132954) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "building_troop_types", force: :cascade do |t|
    t.string "building"
    t.string "troop_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["building"], name: "index_building_troop_types_on_building", unique: true
  end

  create_table "configs", force: :cascade do |t|
    t.string "key"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_configs_on_key", unique: true
  end

  create_table "distributions", force: :cascade do |t|
    t.integer "slot"
    t.string "building"
    t.bigint "player_id", null: false
    t.string "role"
    t.bigint "allocated_troops"
    t.date "distribution_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_distributions_on_player_id"
  end

  create_table "players", force: :cascade do |t|
    t.string "nickname"
    t.string "alliance"
    t.string "troop_type"
    t.string "level"
    t.bigint "march_size"
    t.bigint "group_attack"
    t.bigint "troop_power"
    t.string "slot"
    t.string "wants_captain"
    t.datetime "registration_time"
    t.inet "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nickname"], name: "index_players_on_nickname"
  end

  add_foreign_key "distributions", "players"
end
