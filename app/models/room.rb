class Room < ApplicationRecord
  before_create :generate_uuid
  before_save :normalize_name
  after_create :create_chat

  belongs_to :owner, class_name: "Player", foreign_key: "player_id", primary_key: "uuid"

  has_many :room_players, dependent: :destroy  # Defina esta associação primeiro
  has_many :players, through: :room_players    # Depois defina esta associação

  has_many :games, dependent: :destroy
  has_one :chat, dependent: :destroy

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
    # Ordem fixa de ocupação: A -> C -> B -> D
    sequence = [ "chair_a", "chair_c", "chair_b", "chair_d" ]

    # Obter as cadeiras ocupadas
    occupied = sequence.select { |chair| self[chair].present? }

    # Verificar quantos estão ocupados para decidir a próxima cadeira na ordem
    # Exemplo:
    # 0 ocupados: Próximo deve sentar em A
    # 1 ocupado  (A): Próximo deve sentar em C
    # 2 ocupados (A, C): Próximo deve sentar em B
    # 3 ocupados (A, C, B): Próximo deve sentar em D

    # Primeiro, verificar se a ordem atual de ocupação respeita o prefixo da sequência
    # Ou seja, se há 1 jogador, ele deve estar em A; se há 2, devem estar em A e C, etc.

    expected_occupied = sequence.first(occupied.size)
    order_respected = (occupied == expected_occupied)

    # Próxima cadeira esperada caso a ordem esteja sendo respeitada
    next_chair = sequence[occupied.size] if occupied.size < sequence.size

    # Se a ordem estiver respeitada e ainda há cadeira na sequência para ocupar
    if order_respected && next_chair && self[next_chair].nil?
      # Atribuir a próxima cadeira da sequência
      self[next_chair] = player_name
      save
    else
      # Caso não esteja respeitada ou a cadeira esperada esteja ocupada,
      # atribui cadeira aleatória como antes
      available_chairs = %w[chair_a chair_b chair_c chair_d].select { |chair| self[chair].nil? }

      if available_chairs.any?
        self[available_chairs.sample] = player_name
        save
      else
        raise "Room is full"
      end
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
  def create_chat
    Chat.create!(room_id: self.uuid)
  end
end
