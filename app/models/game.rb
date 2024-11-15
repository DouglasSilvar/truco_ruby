class Game < ApplicationRecord
    belongs_to :room, foreign_key: "room_id", primary_key: "uuid"
    has_many :steps, foreign_key: "game_id", primary_key: "uuid"

    # Inicializa as pontuações dos times e métodos para manipulação de jogo
    validates :score_us, :score_them, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    # Método para atualizar pontuação dos times
    def add_points(team, points)
      if team == "us"
        self.score_us += points
      elsif team == "them"
        self.score_them += points
      end
      save
    end

    def as_json_with_chairs(options = {})
    chairs = {
      chair_a: room.chair_a,
      chair_b: room.chair_b,
      chair_c: room.chair_c,
      chair_d: room.chair_d
    }

    # Constrói manualmente o JSON
    {
      uuid: uuid,
      room_id: room_id,
      score_us: score_us,
      score_them: score_them,
      created_at: created_at,
      updated_at: updated_at,
      end_game_win: end_game_win,
      chairs: chairs
    }
  end


    # Método para verificar se algum time venceu (pontuação mínima de 12)
    def winner
      return "Nós" if score_us >= 12
      return "Eles" if score_them >= 12
      nil
    end
end
