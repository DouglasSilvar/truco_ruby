class CreateGames < ActiveRecord::Migration[7.2]
  def change
    create_table :games, id: false do |t|
      t.string :uuid, primary_key: true
      t.string :room_id, null: false, index: true
      t.integer :score_us, default: 0
      t.integer :score_them, default: 0
      t.timestamps
    end

    add_foreign_key :games, :rooms, column: :room_id, primary_key: :uuid
  end
end
