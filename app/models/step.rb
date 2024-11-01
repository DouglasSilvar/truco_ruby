class Step < ApplicationRecord
    belongs_to :game, foreign_key: 'game_id', primary_key: 'uuid'
  
    validates :number, inclusion: { in: [1, 2, 3] }
    validate :cards_format, :validar_cartas, :validar_vira
  
    CARTAS_VALIDAS = %w[AO AE AC AZ 2O 2E 2C 2Z 3O 3E 3C 3Z 4O 4E 4C 4Z 5O 5E 5C 5Z 6O 6E 6C 6Z 7O 7E 7C 7Z QO QE QC QZ JO JE JC JZ KO KE KC KZ]
  
    # Método para gerar o baralho completo de truco
    def self.generate_deck
      suits = %w[O E C Z]  # O = Ouro, E = Espada, C = Copas, Z = Zap
      ranks = %w[A 2 3 4 5 6 7 Q J K]
      ranks.product(suits).map { |rank, suit| "#{rank}#{suit}" }
    end

    def record_round_winner(round, team)
      if round == 1
        update(first: team)
      elsif round == 2
        update(second: team)
      end
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
  
      if (table_cards - CARTAS_VALIDAS).any?
        errors.add(:table_cards, "contain invalid cards")
      end
    end
  
    # Validação para verificar o formato de cada carta em cards_chair_a até cards_chair_d
    def cards_format
      Rails.logger.info "Entering cards_format validation"
      %i[cards_chair_a cards_chair_b cards_chair_c cards_chair_d].each do |chair|
        player_cards = send(chair)
        Rails.logger.info "Validating cards for #{chair}: #{player_cards.inspect}"
        unless player_cards.all? { |card| CARTAS_VALIDAS.include?(card) }
          errors.add(chair, "must be in the correct format")
        end
      end
    end
  
    # Validação para garantir que a carta 'mania' seja uma carta válida
    def validar_vira
      unless CARTAS_VALIDAS.include?(vira)
        errors.add(:vira, "must be a valid card")
      end
    end
  end
  