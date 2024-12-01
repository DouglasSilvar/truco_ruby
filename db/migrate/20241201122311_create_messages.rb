class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.string :chat_id, null: false
      t.string :player_id, null: false
      t.text :content, null: false, limit: 256
      t.timestamps
    end

    add_index :messages, :chat_id
    add_index :messages, :player_id
    add_foreign_key :messages, :chats, column: :chat_id
    add_foreign_key :messages, :players, column: :player_id, primary_key: :uuid
  end
end