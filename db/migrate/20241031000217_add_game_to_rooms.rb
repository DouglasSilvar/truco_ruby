class AddGameToRooms < ActiveRecord::Migration[7.2]
  def change
    add_column :rooms, :game, :string
  end
end
