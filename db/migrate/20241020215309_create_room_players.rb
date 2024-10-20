class CreateRoomPlayers < ActiveRecord::Migration[6.1]
  def change
    create_table :room_players do |t|
      t.string :room_id
      t.string :player_id

      t.timestamps
    end

    add_index :room_players, [:room_id, :player_id], unique: true
    add_foreign_key :room_players, :rooms, column: :room_id, primary_key: :uuid
    add_foreign_key :room_players, :players, column: :player_id, primary_key: :uuid
  end
end
