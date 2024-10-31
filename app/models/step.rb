class Step < ApplicationRecord
    belongs_to :game, foreign_key: 'game_id', primary_key: 'uuid'
  
    validates :number, inclusion: { in: [1, 2, 3] }
    validate :cards_format, :validar_cartas, :validar_mania
  
    CARTAS_VALIDAS = %w[AO AE AC AZ 2O 2E 2C 2Z 3O 3E 3C 3Z 4O 4E 4C 4Z 5O 5E 5C 5Z 6O 6E 6C 6Z 7O 7E 7C 7Z QO QE QC QZ JO JE JC JZ KO KE KC KZ]
  
    # Método para gerar o baralho completo de truco
    def self.generate_deck
      suits = %w[O E C Z]  # O = Ouro, E = Espada, C = Copas, Z = Zap
      ranks = %w[A 2 3 4 5 6 7 Q J K]
      ranks.product(suits).map { |rank, suit| "#{rank}#{suit}" }
    end
  
    private
  
    # Validação das cartas distribuídas aos jogadores
    def validar_cartas
      %i[cards_chair_a cards_chair_b cards_chair_c cards_chair_d].each do |chair|
        player_cards = send(chair)
        if (player_cards - CARTAS_VALIDAS).any?
          errors.add(chair, "contains invalid cards")
        end
      end

      # Validação para verificar o formato de cada carta em cards_chair_a até cards_chair_d
  def cards_format
    %i[cards_chair_a cards_chair_b cards_chair_c cards_chair_d].each do |cards_field|
      cards_array = self[cards_field] || []
      unless cards_array.all? { |card| CARTAS_VALIDAS.include?(card) }
        errors.add(cards_field, "must be in the correct format")
      end
    end
  end

  def validar_cartas
    if (table_cards - CARTAS_VALIDAS).any?
      errors.add(:table_cards, "contain invalid cards")
    end
  end
  
      if (table_cards - CARTAS_VALIDAS).any?
        errors.add(:table_cards, "contain invalid cards")
      end
    end
  
    # Validação para garantir que a carta 'mania' seja uma carta válida
    def validar_mania
      unless CARTAS_VALIDAS.include?(mania)
        errors.add(:mania, "must be a valid card")
      end
    end
  
    # Validação personalizada para verificar a estrutura dos arrays de cartas de cada jogador
    def cards_format
      %i[cards_chair_a cards_chair_b cards_chair_c cards_chair_d].each do |chair|
        player_cards = send(chair)
        unless player_cards.all? { |card| card.match?(/\A[A-Z]{1,2}[A-Z]\z/) }
          errors.add(chair, "must be in the correct format")
        end
      end
    end
  end
  