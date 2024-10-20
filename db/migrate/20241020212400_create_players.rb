class CreatePlayers < ActiveRecord::Migration[6.1]
  def change
    create_table :players, id: false do |t|  # id: false evita a criação do id numérico
      t.string :uuid, primary_key: true  # UUID como primary key
      t.string :name, null: false

      t.timestamps
    end

    add_index :players, :uuid, unique: true
  end
end
