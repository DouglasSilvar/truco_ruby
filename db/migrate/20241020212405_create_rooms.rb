class CreateRooms < ActiveRecord::Migration[6.1]
  def change
    create_table :rooms, id: false do |t|  # id: false evita a criação do id numérico
      t.string :uuid, primary_key: true  # UUID como primary key
      t.string :name, null: false, unique: true
      t.string :player_id, null: false  # Relacionamento com Player como owner

      t.timestamps
    end

    add_index :rooms, :uuid, unique: true
    add_foreign_key :rooms, :players, column: :player_id, primary_key: "uuid"
  end
end
