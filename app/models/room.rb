class Room < ApplicationRecord
    before_create :generate_uuid
  
    belongs_to :owner, class_name: 'Player', foreign_key: 'player_id', primary_key: 'uuid'
    has_many :room_players
    has_many :players, through: :room_players
  
    validates :name, presence: true, length: { maximum: 36 }
  
    def as_json(options = {})
      super(options.merge(include: { owner: { only: [:player_id, :name] } }))
    end
  
    private
  
    def generate_uuid
      self.uuid = SecureRandom.uuid
    end
  end
  