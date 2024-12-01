class Message < ApplicationRecord
  belongs_to :chat, foreign_key: :chat_id
  belongs_to :player, foreign_key: :player_id, primary_key: :uuid

  validates :content, presence: true, length: { maximum: 256 }
  validates :chat_id, presence: true
  validates :player_id, presence: true
end
