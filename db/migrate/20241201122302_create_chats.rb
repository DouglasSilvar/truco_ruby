class CreateChats < ActiveRecord::Migration[7.0]
  def change
    create_table :chats do |t|
      t.string :room_id, null: false
      t.timestamps
    end

    add_index :chats, :room_id
    add_foreign_key :chats, :rooms, column: :room_id, primary_key: :uuid
  end
end
