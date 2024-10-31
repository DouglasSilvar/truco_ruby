class Game < ApplicationRecord
    belongs_to :room, foreign_key: 'room_id', primary_key: 'uuid'
  
    # Inicializa as pontuações dos times e métodos para manipulação de jogo
    validates :score_us, :score_them, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
    # Método para atualizar pontuação dos times
    def add_points(team, points)
      if team == 'us'
        self.score_us += points
      elsif team == 'them'
        self.score_them += points
      end
      save
    end
  
    # Método para verificar se algum time venceu (pontuação mínima de 12)
    def winner
      return 'Nós' if score_us >= 12
      return 'Eles' if score_them >= 12
      nil
    end
  end
  