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

  def play_move(card:, coverup:)
    # Validações iniciais
    return { error: "Player is not part of this game", status: :forbidden } unless valid_player?

    if card.nil?
      return { error: "No card provided for play", status: :unprocessable_entity }
    end

    if @step.table_cards.size >= 4
      return { error: "Cannot play card, table already has 4 cards", status: :forbidden }
    end

    player_chair = find_player_chair
    unless @step.send("cards_#{player_chair}").include?(card)
      return { error: "Invalid card or card not in player's hand", status: :unprocessable_entity }
    end

    # Processa a jogada
    process_card_play(card, player_chair, coverup)

    # Resposta de sucesso
    { status: :ok }
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

  # Identifica a cadeira do jogador
  def find_player_chair
    @game.room.attributes.slice("chair_a", "chair_b", "chair_c", "chair_d").find do |_, name|
      name == @player_name
    end&.first
  end

  # Processa a jogada da carta
  def process_card_play(card, player_chair, coverup)
    card_to_save = coverup ? "EC" : card

    # Adiciona a carta à mesa
    @step.table_cards << card_to_save
    @step.update(table_cards: @step.table_cards)

    # Remove a carta da mão do jogador
    player_cards = @step.send("cards_#{player_chair}")
    player_cards.delete(card)
    @step.update("cards_#{player_chair}" => player_cards)

    # Salva a origem da carta
    save_card_origin(card_to_save, player_chair)

    # Determina o próximo jogador ou verifica o vencedor da rodada
    if @step.fourth_card_origin.nil?
      set_next_player(player_chair)
    else
      determine_round_winner
    end

    # Determina o vencedor do jogo, se aplicável
    determine_game_winner
  end

  # Salva a origem da carta jogada
  def save_card_origin(card, player_chair)
    team = %w[A B].include?(player_chair.strip.upcase[-1]) ? "NOS" : "ELES"
    card_origin_record = "#{card}---#{player_chair}---#{team}---#{@player_name}"

    %i[first_card_origin second_card_origin third_card_origin fourth_card_origin].each do |column|
      if @step.send(column).nil?
        @step.update(column => card_origin_record)
        break
      end
    end
  end

  # Define o próximo jogador
  def set_next_player(player_chair)
    chair_order = %w[A D B C]
    next_chair = chair_order[(chair_order.index(player_chair[-1].upcase) + 1) % chair_order.length]
    next_player_name = @game.room.send("chair_#{next_chair.downcase}")
    @step.update(player_time: next_player_name)
  end

  # Determina o vencedor da rodada
  def determine_round_winner
    # Reaproveitar lógica existente na controller
    determine_game_winner(@step)
  end

  # Determina o vencedor do jogo
  def determine_game_winner
    case
    when @step.first == "EMPACHE"
      # Regras para empates e outros casos
      # (lógica completa pode ser movida para cá ou mantida como está)
    end
  end
end
