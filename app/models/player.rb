class Player < ApplicationRecord
    self.primary_key = 'uuid'
  
    before_create :generate_uuid
  
    validates :name, presence: true
    validates :uuid, uniqueness: true
  
    has_many :room_players
    has_many :rooms, through: :room_players
  
    def as_json(options = {})
      super(options.merge(except: [:uuid], methods: [:player_id]))
    end
  
    def player_id
      uuid
    end
  
    private
  
    def generate_uuid
      self.uuid = SecureRandom.uuid if self.uuid.blank?
    end
  end
  