# app/services/game_service.rb
class GameService
  def initialize(game, player_name)
    @game = game
    @player_name = player_name
    @step = current_step
  end

  # Método principal para exibir o jogo
  def show_game
    player_chair = find_player_chair
    step = latest_step

    return { error: "No step available for this game", status: :not_found } unless step

    # Formata os dados do step para o jogador ou telespectador
    step_data = format_step_data(step, player_chair)

    # Monta o JSON no padrão esperado
    response_data = @game.as_json_with_chairs.merge(
      step: step_data,
      room_name: @game.room.name,
      owner: { name: @game.room.owner.name }
    )

    response_data
  end

  private

  # Identifica a cadeira do jogador
  def find_player_chair
    @game.room.attributes.slice("chair_a", "chair_b", "chair_c", "chair_d").find do |_, name|
      name == @player_name
    end&.first
  end

  # Busca o último step do jogo
  def latest_step
    @game.steps.order(:number).last
  end

  # Formata os dados do step dependendo do jogador ou telespectador
  def format_step_data(step, player_chair)
    step_data = step.as_json

    if player_chair
      # Jogador: mostra apenas suas cartas
      %w[cards_chair_a cards_chair_b cards_chair_c cards_chair_d].each do |chair|
        step_data[chair] = (chair == "cards_#{player_chair}") ? step.send(chair) : []
      end
    else
      # Telespectador: remove os arrays de cartas
      %w[cards_chair_a cards_chair_b cards_chair_c cards_chair_d].each do |chair|
        step_data.delete(chair)
      end
    end

    step_data
  end

  # Determina o step atual
  def current_step
    @game.steps.order(:number).last
  end

  # Verifica se o jogador é válido
  def valid_player?
    find_player_chair.present?
  end
end
