
ActiveRecord::Schema[7.2].define(version: 2024_11_02_105033) do
  create_table "games", primary_key: "uuid", id: :string, force: :cascade do |t|
    t.string "room_id", null: false
    t.integer "score_us", default: 0
    t.integer "score_them", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["game_id"], name: "index_steps_on_game_id"
  end

  add_foreign_key "games", "rooms", primary_key: "uuid"
  add_foreign_key "room_players", "players", primary_key: "uuid"
  add_foreign_key "room_players", "rooms", primary_key: "uuid"
  add_foreign_key "rooms", "players", primary_key: "uuid"
  add_foreign_key "steps", "games", primary_key: "uuid"
end
