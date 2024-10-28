class AddKickToRoomPlayers < ActiveRecord::Migration[6.0]
  def change
    add_column :room_players, :kick, :boolean, default: false
  end
end
