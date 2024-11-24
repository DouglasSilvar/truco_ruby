class GamesController < ApplicationController
  before_action :authenticate_player, only: [ :show, :play_move ]
  before_action :set_game, only: [ :show, :play_move, :call, :collect ]

  def show
    player_name = request.headers["name"]
    game = Game.find_by(uuid: params[:uuid])

    if game
      # Verifica se o solicitante é um jogador
      player_chair = find_player_chair(game.room, player_name)

      # Permitir telespectadores
      unless player_chair || authenticated_user?(player_name)
        render json: { error: "User is not authorized to view this game" }, status: :forbidden
        return
      end

      # Carregar o último `step` do jogo
      step = game.steps.order(:number).last
      if step.nil?
        render json: { error: "No step available for this game" }, status: :not_found
        return
      end

      step_data = step.as_json

      if player_chair
        # Jogador: exibe apenas as cartas do jogador
        %w[cards_chair_a cards_chair_b cards_chair_c cards_chair_d].each do |chair|
          step_data[chair] = (chair == "cards_#{player_chair}") ? step.send(chair) : []
        end
      else
        # Telespectador: remove os arrays de cartas
        %w[cards_chair_a cards_chair_b cards_chair_c cards_chair_d].each do |chair|
          step_data.delete(chair)
        end
      end

      # Adiciona o owner da sala ao JSON
      owner_data = { name: game.room.owner.name } if game.room.owner

      render json: game.as_json_with_chairs.merge(
        step: step_data,
        room_name: game.room.name,
        owner: owner_data
      )
    else
      render json: { error: "Game not found" }, status: :not_found
    end
  end

  def play_move
    card = params[:card]
    coverup = ActiveModel::Type::Boolean.new.cast(params[:coverup])

    step = current_step
    player_name = request.headers["name"]

    unless valid_player?(player_name)
      render json: { error: "Player is not part of this game" }, status: :forbidden
      return
    end

    if card
      if step.table_cards.size >= 4
        render json: { error: "Cannot play card, table already has 4 cards" }, status: :forbidden
        return
      end

      unless step.send("cards_#{find_player_chair(@game.room, player_name)}").include?(card)
        render json: { error: "Invalid card or card not in player's hand" }, status: :unprocessable_entity
        return
      end

      play_card(step, player_name, card, coverup)
    end

    head :ok
  end

  def call
    accept = ActiveModel::Type::Boolean.new.cast(params[:accept])
    call = params[:call]
    player_name = request.headers["name"]

    step = current_step

    if call
      handle_truco_call(step, call, player_name)
      return
    end

    if accept == true || accept == false
      unless valid_player?(player_name)
        render json: { error: "Player is not part of this game" }, status: :forbidden
        return
      end

      if truco_call_pending?(step)
        register_accept_decision(step, player_name, accept)
        head :ok
        return
      else
        render json: { error: "No truco call to accept or reject" }, status: :unprocessable_entity
        return
      end
    end
  end

  def collect
    collect = ActiveModel::Type::Boolean.new.cast(params[:collect])
    player_name = request.headers["name"]

    step = current_step

    if collect
      handle_collect(step, find_player_chair(@game.room, player_name))
    else
      render json: { error: "Invalid collect action" }, status: :unprocessable_entity
    end
  end

  private

  def find_player_chair(room, player_name)
    room.attributes.slice("chair_a", "chair_b", "chair_c", "chair_d").find { |_, name| name == player_name }&.first
  end

  def set_game
    @game = Game.find_by(uuid: params[:uuid])
    render json: { error: "Game not found" }, status: :not_found unless @game
  end

# Método para determinar o vencedor da rodada quando 4 cartas estão na mesa
def determine_round_winner(step)
  table_cards = step.table_cards
  card_origins = [
    step.first_card_origin,
    step.second_card_origin,
    step.third_card_origin,
    step.fourth_card_origin
  ].compact

  # Retorna se não houver exatamente 4 cartas na mesa
  return if table_cards.size != 4 || card_origins.size != 4

  # Identificar o time vencedor e a carta mais forte
  winner_team, strongest_card_origin = calculate_winner(table_cards, card_origins, step.vira)

  # Verifica se houve um empate ou se não foi possível identificar a origem da carta mais forte
  if winner_team == "EMPACHE" || strongest_card_origin.nil?
    # Atualiza o campo apropriado (first, second ou third) com "EMPACHE"
    if step.first.nil?
      step.update(first: "EMPACHE")
    elsif step.second.nil?
      step.update(second: "EMPACHE")
    else
      step.update(third: "EMPACHE")
    end

    # Determina o próximo jogador após o empate
    if step.fourth_card_origin
      current_chair = step.fourth_card_origin.split("---")[1]
      current_chair_letter = current_chair[-1].upcase
      chair_order = %w[A D B C]
      next_chair = chair_order[(chair_order.index(current_chair_letter) + 1) % chair_order.length]
      next_player_name = @game.room.send("chair_#{next_chair.downcase}")
      step.update(player_time: next_player_name)
    else
      render json: { error: "Unable to determine next chair" }, status: :unprocessable_entity
      return
    end

    return # Finaliza a execução para evitar operações adicionais com `nil`
  end

  # Salva o vencedor no campo apropriado (first, second ou third)
  if step.first.nil?
    step.update(
      first: winner_team,
      player_time: strongest_card_origin&.split("---")&.fetch(3, nil)
    )
  elsif step.second.nil?
    step.update(
      second: winner_team,
      player_time: strongest_card_origin&.split("---")&.fetch(3, nil)
    )
  else
    step.update(
      third: winner_team,
      player_time: strongest_card_origin&.split("---")&.fetch(3, nil)
    )
  end
end



##############################################################################################################################################
# Método auxiliar para calcular o vencedor da rodada com base nas regras
def calculate_winner(table_cards, card_origins, vira)
  card_hierarchy = %w[4 5 6 7 Q J K A 2 3]
  vira_value = vira[0..-2] # Remove o último caractere (naipe) da carta
  mania_card = card_hierarchy[(card_hierarchy.index(vira_value) + 1) % card_hierarchy.size] if card_hierarchy.index(vira_value)

  # Avaliar a força das cartas
  card_values = card_origins.map do |origin|
    card, chair, team, player_name = origin.split("---")
    {
      card: card,
      chair: chair,
      team: team,
      player_name: player_name,
      strength: calculate_card_strength(card, mania_card, card_hierarchy, chair)
    }
  end

  # Verifica se uma carta "mania" foi jogada
  mania_played = card_values.find { |entry| entry[:card] == mania_card }
  return [ mania_played[:team], mania_played ] if mania_played

  # Agrupando por equipe para determinar o maior valor em cada time
  teams = card_values.group_by { |entry| entry[:team] }
  max_nos_card = teams["NOS"]&.max_by { |entry| entry[:strength] }
  max_eles_card = teams["ELES"]&.max_by { |entry| entry[:strength] }

  # Determina empate caso as forças sejam iguais
  if max_nos_card && max_eles_card && max_nos_card[:strength] == max_eles_card[:strength]
    return [ "EMPACHE", nil ]
  end

  # Define o time vencedor com a carta mais forte
  winning_team = max_nos_card[:strength] > max_eles_card[:strength] ? "NOS" : "ELES"
  strongest_card = [ max_nos_card, max_eles_card ].compact.max_by { |entry| entry[:strength] }
  [ winning_team, "#{strongest_card[:card]}---#{strongest_card[:chair]}---#{strongest_card[:team]}---#{strongest_card[:player_name]}" ]
end

# Calcula a força de uma carta considerando a MANIA e hierarquia de naipes
def calculate_card_strength(card, mania_card, hierarchy, chair)
  # Hierarquia básica de força
  return 0 if card == "EC"
  card_value = card[0..-2] # Remove o último caractere (naipe) da carta
  base_strength = hierarchy.index(card_value)
  # Se a carta for MANIA, ajuste a força com base no naipe
  if card_value == mania_card
    suit_order = %w[O E C Z]
    card_nipe = card[-1]
    base_strength = hierarchy.size + suit_order.index(card_nipe)
  end
  base_strength
end

def handle_collect(step, player_chair)
  # Verifica se há um vencedor para o round atual
  if step.win && step.win != "EMPT"
    game = step.game # Obtem o jogo associado ao step atual

        # Define a pontuação com base nos parâmetros de truco
        additional_points = calculate_additional_points(step)

        # Incrementa o placar com base no vencedor e pontos calculados
        if step.win == "NOS"
          game.increment!(:score_us, additional_points)
        elsif step.win == "ELES"
          game.increment!(:score_them, additional_points)
        end

    # Verifica se o placar atingiu ou excedeu 12 pontos
    winner = if game.score_us >= 12
               "NOS"
    elsif game.score_them >= 12
               "ELES"
    end

    if winner
      game.update(end_game_win: winner)
      step.update(
        table_cards: [],
        first_card_origin: nil,
        second_card_origin: nil,
        third_card_origin: nil,
        fourth_card_origin: nil,
        win: nil
      )
      # Atualiza a coluna `game` na tabela `room` para nil
      game.room.update(game: nil)
      game.room.room_players.update_all(ready: false)
      render json: { message: "Jogo finalizado. #{winner} venceu!", game_id: game.uuid }, status: :ok
      return
    end

    # Reinicia o step atual para o próximo round
    reset_step(step, Step.generate_deck.shuffle)
    if step.errors.any?
      render json: { error: "Falha ao reiniciar round", details: step.errors.full_messages }, status: :internal_server_error
    else
      render json: { message: "Ponto computado e round reiniciado", step_id: step.id }, status: :ok
    end
  else
    # Se não houver vencedor, apenas limpa as cartas e origens do step atual
    step.update(
      table_cards: [],
      first_card_origin: nil,
      second_card_origin: nil,
      third_card_origin: nil,
      fourth_card_origin: nil
    )

    head :ok
  end
end

private

def reset_step(step, deck = nil)
  # Limpa os campos do step
  step.update(
    cards_chair_a: deck&.shift(3),
    cards_chair_b: deck&.shift(3),
    cards_chair_c: deck&.shift(3),
    cards_chair_d: deck&.shift(3),
    table_cards: [],
    vira: deck&.shift,
    first_card_origin: nil,
    second_card_origin: nil,
    third_card_origin: nil,
    fourth_card_origin: nil,
    first: nil,
    second: nil,
    third: nil,
    player_call_3: nil,
    player_call_6: nil,
    player_call_9: nil,
    player_call_12: nil,
    is_accept_first: nil,
    is_accept_second: nil,
    win: nil
  )
end


def determine_game_winner(step)
  case
  when step.first == "EMPACHE"
    # Regra 4: Primeira rodada empachada, o vencedor é quem ganhou a segunda, ou a terceira decide se a segunda também é empachada.
    case step.second
    when "EMPACHE"
      step.update(win: (step.third == "EMPACHE" ? "EMP" : step.third)) # Se terceira também é empachada, jogo sem vencedor, senão, terceira define.
    else
      step.update(win: step.second) # Se a segunda não é empachada, ela define o vencedor.
    end

  when step.first && step.second == "EMPACHE"
    # Regra 2: Primeira rodada ganha, segunda empachada, primeira define o vencedor.
    step.update(win: step.first)

  when step.first && step.first == step.second
    # Regra 1: O mesmo time vence as duas primeiras, ele é o vencedor.
    step.update(win: step.first)

  when step.first && step.first != step.second && step.second != "EMPACHE"
    # Regra 3: Times diferentes ganharam a primeira e a segunda rodada, a terceira decide.
    step.update(win: (step.third == "EMPACHE" ? step.first : step.third)) # Se a terceira é empachada, primeiro vencedor ganha, senão, terceira define.

  when step.first == "EMPACHE" && step.second == "EMPACHE" && step.third == "EMPACHE"
    # Regra 5: Todas as rodadas são empachadas, o jogo termina sem vencedor.
    step.update(win: "EMP")
  end
end

def handle_truco_call(step, call, player_name)
  valid_calls = [ 3, 6, 9, 12 ] # Valores válidos para chamadas de truco
  unless valid_calls.include?(call.to_i)
    render json: { error: "Invalid truco call" }, status: :unprocessable_entity
    return
  end

  # Determina o time do jogador com base na cadeira
  player_chair = find_player_chair(step.game.room, player_name)
  unless player_chair
    render json: { error: "Player is not part of this game" }, status: :forbidden
    return
  end

  team = %w[a b].include?(player_chair[-1].downcase) ? "NOS" : "ELES"
  player_call_value = "#{player_name}---#{team}"

  case call.to_i
  when 3
    if step.player_call_3.nil?
      step.update(player_call_3: player_call_value, player_time: nil)
      render json: { message: "Truco called at level 3 by #{player_name} (#{team})" }, status: :ok
    else
      render json: { error: "Level 3 already called" }, status: :unprocessable_entity
    end
  when 6
    if step.player_call_6.nil?
      step.update(
        player_call_6: player_call_value,
        is_accept_first: nil,
        is_accept_second: nil,
        player_time: nil)
      render json: { message: "Truco called at level 6 by #{player_name} (#{team})" }, status: :ok
    else
      render json: { error: "Level 6 already called" }, status: :unprocessable_entity
    end
  when 9
    if step.player_call_9.nil?
      step.update(
        player_call_9: player_call_value,
        is_accept_first: nil,
        is_accept_second: nil,
        player_time: nil)
      render json: { message: "Truco called at level 9 by #{player_name} (#{team})" }, status: :ok
    else
      render json: { error: "Level 9 already called" }, status: :unprocessable_entity
    end
  when 12
    if step.player_call_12.nil?
      step.update(
        player_call_12: player_call_value,
        is_accept_first: nil,
        is_accept_second: nil,
        player_time: nil)
      render json: { message: "Truco called at level 12 by #{player_name} (#{team})" }, status: :ok
    else
      render json: { error: "Level 12 already called" }, status: :unprocessable_entity
    end
  end
end

def register_accept_decision(step, player_name, accept)
  player_chair = find_player_chair(step.game.room, player_name)
  unless player_chair
    return
  end

  # Determina o time com base na cadeira
  team = %w[a b].include?(player_chair[-1].downcase) ? "NOS" : "ELES"
  decision = "#{player_name}---#{accept ? 'yes' : 'no'}---#{team}"

  if step.is_accept_first.nil?
    # Salva no campo `is_accept_first` se ele estiver vazio
    step.update(is_accept_first: decision)
  elsif step.is_accept_second.nil?
    # Verifica se o mesmo player já salvou no `is_accept_first`
    existing_player = step.is_accept_first&.split("---")&.first
    if existing_player != player_name
      # Salva no campo `is_accept_second` se ele estiver vazio e não for duplicado
      step.update(is_accept_second: decision)
      handle_truco_decision(step)
    else
    end
  else
  end
end

def handle_truco_decision(step)
  # Determina o último jogador que fez uma chamada de truco
  truco_calls = [
    step.player_call_3,
    step.player_call_6,
    step.player_call_9,
    step.player_call_12
  ]

  last_truco_call = truco_calls.compact.first # Pega a chamada mais prioritária (12 > 9 > 6 > 3)

  if last_truco_call
    # Extrai informações do jogador que fez a última chamada
    player_data = last_truco_call.split("---")
    truco_player = player_data[0] # Nome do jogador que pediu truco
    truco_team = player_data[1]   # Nome do time que pediu truco
  end

  # Verifica a decisão do segundo jogador do time oposto
  if step.is_accept_second.include?("---no")
    # Atualiza a coluna 'win' com o time que pediu truco
    step.update!(win: truco_team)

    # Atualiza a coluna 'player_time' com o último jogador que pediu truco
    step.update!(player_time: truco_player)
  elsif step.is_accept_second.include?("---yes")
    # Apenas atualiza o último jogador que pediu truco como próximo a jogar
    step.update!(player_time: truco_player)
  end
end



def calculate_additional_points(step)
  puts "Calculating points for step: #{step.inspect}"

  # Prioriza o menor valor de truco primeiro
  case
  when step.player_call_12.present?
    puts "player_call_3 detected: #{step.player_call_3.inspect}"
    step.is_accept_second.include?("---yes") ? 12 : 9
  when step.player_call_9.present?
    puts "player_call_6 detected: #{step.player_call_6.inspect}"
    step.is_accept_second.include?("---yes") ? 9 : 6
  when step.player_call_6.present?
    puts "player_call_9 detected: #{step.player_call_9.inspect}"
    step.is_accept_second.include?("---yes") ? 6 : 3
  when step.player_call_3.present?
    puts "player_call_12 detected: #{step.player_call_12.inspect}"
    step.is_accept_second.include?("---yes") ? 3 : 1
  else
    puts "No player_call found, returning default 1"
    1
  end
end

def current_step
  @game.steps.order(:number).last
end

def valid_player?(player_name)
  find_player_chair(@game.room, player_name).present?
end

def truco_call_pending?(step)
  step.player_call_3 || step.player_call_6 || step.player_call_9 || step.player_call_12
end

def play_card(step, player_name, card, coverup)
  player_chair = find_player_chair(@game.room, player_name)
  card_to_save = coverup ? "EC" : card

  # Add card to table_cards
  step.table_cards << card_to_save
  step.update(table_cards: step.table_cards)

  # Remove card from player's hand
  player_cards = step.send("cards_#{player_chair}")
  player_cards.delete(card)
  step.update("cards_#{player_chair}" => player_cards)

  save_card_origin(step, card_to_save, player_chair, player_name)
  set_next_player(step, player_chair) if step.fourth_card_origin.nil?
  determine_round_winner(step)
  determine_game_winner(step)
end

def save_card_origin(step, card, player_chair, player_name)
  team = %w[A B].include?(player_chair.strip.upcase[-1]) ? "NOS" : "ELES"
  card_origin_record = "#{card}---#{player_chair}---#{team}---#{player_name}"

  %i[first_card_origin second_card_origin third_card_origin fourth_card_origin].each do |column|
    if step.send(column).nil?
      step.update(column => card_origin_record)
      break
    end
  end
end

def set_next_player(step, player_chair)
  chair_order = %w[A D B C]
  next_chair = chair_order[(chair_order.index(player_chair[-1].upcase) + 1) % chair_order.length]
  next_player_name = @game.room.send("chair_#{next_chair.downcase}")
  step.update(player_time: next_player_name)
end

end
