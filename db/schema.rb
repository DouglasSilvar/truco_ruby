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

ActiveRecord::Schema[7.2].define(version: 2024_11_13_212847) do
  create_table "games", primary_key: "uuid", id: :string, force: :cascade do |t|
    t.string "room_id", null: false
    t.integer "score_us", default: 0
    t.integer "score_them", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "game_show", default: {}
    t.index ["room_id"], name: "index_games_on_room_id"
  end

  create_table "players", primary_key: "uuid", id: :string, force: :cascade do |t|
    t.string "name", limit: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_players_on_name", unique: true
    t.index ["uuid"], name: "index_players_on_uuid", unique: true
  end

  create_table "room_players", force: :cascade do |t|
    t.string "room_id"
    t.string "player_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "kick", default: false
    t.boolean "ready", default: false
    t.index ["room_id", "player_id"], name: "index_room_players_on_room_id_and_player_id", unique: true
  end

  create_table "rooms", primary_key: "uuid", id: :string, force: :cascade do |t|
    t.string "name", null: false
    t.string "player_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "chair_a"
    t.string "chair_b"
    t.string "chair_c"
    t.string "chair_d"
    t.string "password", limit: 4
    t.string "game"
    t.string "room_owner"
    t.json "room_show", default: {}
    t.index ["uuid"], name: "index_rooms_on_uuid", unique: true
  end

  create_table "steps", force: :cascade do |t|
    t.string "game_id", null: false
    t.integer "number", default: 1, null: false
    t.json "table_cards", default: []
    t.string "player_time"
    t.string "player_call_3"
    t.string "player_call_6"
    t.string "player_call_9"
    t.string "player_call_12"
    t.string "vira"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "cards_chair_a", default: []
    t.json "cards_chair_b", default: []
    t.json "cards_chair_c", default: []
    t.json "cards_chair_d", default: []
    t.string "first"
    t.string "second"
    t.string "first_card_origin"
    t.string "second_card_origin"
    t.string "third_card_origin"
    t.string "fourth_card_origin"
    t.string "win", limit: 4
    t.string "third"
    t.index ["game_id"], name: "index_steps_on_game_id"
  end

  add_foreign_key "games", "rooms", primary_key: "uuid"
  add_foreign_key "room_players", "players", primary_key: "uuid"
  add_foreign_key "room_players", "rooms", primary_key: "uuid"
  add_foreign_key "rooms", "players", primary_key: "uuid"
  add_foreign_key "steps", "games", primary_key: "uuid"
end
