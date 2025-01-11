class AddIsTwoPlayersToRoomsAndGames < ActiveRecord::Migration[7.2]
  def change
    add_column :rooms, :is_two_players, :boolean, default: false
    add_column :games, :is_two_players, :boolean, default: false
  end
end
