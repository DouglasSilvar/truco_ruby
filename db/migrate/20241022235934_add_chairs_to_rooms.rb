class AddChairsToRooms < ActiveRecord::Migration[6.1]
  def change
    add_column :rooms, :chair_a, :binary, limit: 16
    add_column :rooms, :chair_b, :binary, limit: 16
    add_column :rooms, :chair_c, :binary, limit: 16
    add_column :rooms, :chair_d, :binary, limit: 16
  end
end
