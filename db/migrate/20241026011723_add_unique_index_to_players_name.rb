class AddUniqueIndexToPlayersName < ActiveRecord::Migration[7.2]
  def change
    add_index :players, :name, unique: true
  end
end
