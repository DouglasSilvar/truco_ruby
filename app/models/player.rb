class Player < ApplicationRecord
  self.primary_key = 'uuid'

  before_create :generate_uuid
  before_save :normalize_name

  validates :name, presence: true, uniqueness: true, length: { maximum: 20 }
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

  def normalize_name
    self.name = normalize_string(self.name)
  end

  def normalize_string(str)
    # Remove acentos, substitui espaços por underscores e remove caracteres especiais
    str.downcase
       .gsub(/\s+/, '_')                      # Substitui espaços por underscore
       .gsub(/[áàãâä]/, 'a')
       .gsub(/[éèêë]/, 'e')
       .gsub(/[íìîï]/, 'i')
       .gsub(/[óòõôö]/, 'o')
       .gsub(/[úùûü]/, 'u')
       .gsub(/[ç]/, 'c')
       .gsub(/[^a-z0-9_]/, '')                # Remove caracteres especiais
  end
end
