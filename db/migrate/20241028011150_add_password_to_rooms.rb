class AddPasswordToRooms < ActiveRecord::Migration[6.0]
  def change
    add_column :rooms, :password, :string, limit: 4
  end
end
