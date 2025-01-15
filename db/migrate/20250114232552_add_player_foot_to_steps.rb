class AddPlayerFootToSteps < ActiveRecord::Migration[6.1]
  def change
    add_column :steps, :player_foot, :string
  end
end
