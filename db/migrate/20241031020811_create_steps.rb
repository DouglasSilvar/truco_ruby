class CreateSteps < ActiveRecord::Migration[7.2]
  def change
    create_table :steps do |t|
      t.string :game_id, null: false, index: true
      t.integer :number, null: false, default: 1
      t.json :cards, default: []
      t.json :table_cards, default: []
      t.string :player_time
      t.string :player_call_3
      t.string :player_call_6
      t.string :player_call_9
      t.string :player_call_12
      t.string :mania  # Adicionando a coluna 'mania' como string
      t.timestamps
    end

    add_foreign_key :steps, :games, column: :game_id, primary_key: :uuid
  end
end
