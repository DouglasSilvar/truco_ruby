class Chat < ApplicationRecord
  belongs_to :room, foreign_key: :room_id, primary_key: :uuid
  has_many :messages, dependent: :destroy

  validates :room_id, presence: true
  def recent_messages(limit = 12)
    messages.order(created_at: :desc).limit(limit).map do |message|
      {
        player_name: message.player.name,
        date_created: message.created_at.strftime("%Y-%m-%d %H:%M:%S"),
        content: message.content
      }
    end
  end
end
