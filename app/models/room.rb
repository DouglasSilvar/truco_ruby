class Room < ApplicationRecord
  before_create :generate_uuid
  before_save :normalize_name

  belongs_to :owner, class_name: "Player", foreign_key: "player_id", primary_key: "uuid"

  has_many :room_players, dependent: :destroy  # Defina esta associação primeiro
  has_many :players, through: :room_players    # Depois defina esta associação

  has_many :games, dependent: :destroy

  validates :name, presence: true, length: { maximum: 20 }

  # Modificando o as_json para excluir o campo password e adicionar o campo protected
  def as_json(options = {})
    super(options.merge(
      except: [ :player_id, :chair_a, :chair_b, :chair_c, :chair_d, :password ],
      include: { owner: { only: [ :name ] } }
    )).merge(protected: password.present?, game: game)
  end

  # Método para preencher aleatoriamente as cadeiras com o nome do jogador
  def assign_random_chair(player_name)
    available_chairs = %w[chair_a chair_b chair_c chair_d].select { |chair| self[chair].nil? }

    if available_chairs.any?
      self[available_chairs.sample] = player_name
      save
    else
      raise "Room is full"
    end
  end

  # Método para remover um jogador da cadeira usando o nome do jogador
  def remove_player_from_chair(player_name)
    %w[chair_a chair_b chair_c chair_d].each do |chair|
      if self[chair] == player_name
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

  def normalize_name
    self.name = normalize_string(self.name)
  end

  def normalize_string(str)
    # Remove acentos, substitui espaços por underscores e remove caracteres especiais
    str.downcase
       .gsub(/\s+/, "_")                      # Substitui espaços por underscore
       .gsub(/[áàãâä]/, "a")
       .gsub(/[éèêë]/, "e")
       .gsub(/[íìîï]/, "i")
       .gsub(/[óòõôö]/, "o")
       .gsub(/[úùûü]/, "u")
       .gsub(/[ç]/, "c")
       .gsub(/[^a-z0-9_]/, "")                # Remove caracteres especiais
  end
end
