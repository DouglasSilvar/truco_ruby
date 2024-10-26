class ChangeChairsToStorePlayerNames < ActiveRecord::Migration[7.2]
  def change
    change_column :rooms, :chair_a, :string
    change_column :rooms, :chair_b, :string
    change_column :rooms, :chair_c, :string
    change_column :rooms, :chair_d, :string
  end
end
