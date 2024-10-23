class Room < ApplicationRecord
  before_create :generate_uuid

  belongs_to :owner, class_name: 'Player', foreign_key: 'player_id', primary_key: 'uuid'
  has_many :room_players
  has_many :players, through: :room_players

  validates :name, presence: true, length: { maximum: 36 }

  def as_json(options = {})
    super(options.merge(include: { owner: { only: [:player_id, :name] } }))
  end


  # Método para preencher aleatoriamente as cadeiras
  def assign_random_chair(player_uuid)
    available_chairs = %w[chair_a chair_b chair_c chair_d].select { |chair| self[chair].nil? }

    if available_chairs.any?
      self[available_chairs.sample] = player_uuid
      save
    else
      raise "Room is full"
    end
  end

  # Método para remover um player da cadeira
  def remove_player_from_chair(player_uuid)
    %w[chair_a chair_b chair_c chair_d].each do |chair|
      if self[chair] == player_uuid
        self[chair] = nil
        save
        break
      end
    end
  end

  private

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end
end
