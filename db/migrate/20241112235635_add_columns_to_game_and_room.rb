class AddColumnsToGameAndRoom < ActiveRecord::Migration[7.2]
  def change
    add_column :games, :game_show, :json, default: {}
    add_column :rooms, :room_show, :json, default: {}
    add_column :steps, :win, :string, limit: 4
  end
end
