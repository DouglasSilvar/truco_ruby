class AddReadyToRoomPlayers < ActiveRecord::Migration[6.1]
  def change
    add_column :room_players, :ready, :boolean, default: false
  end
end
