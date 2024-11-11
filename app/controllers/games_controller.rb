class GamesController < ApplicationController
  before_action :authenticate_player, only: [ :show, :play_move ]
  before_action :set_game, only: [ :show, :play_move ]

  def show
    player_name = request.headers["name"]
    game = Game.find_by(uuid: params[:uuid])

    if game
      player_chair = find_player_chair(game.room, player_name)
      unless player_chair
        render json: { error: "Player is not part of this game" }, status: :forbidden
        return
      end

      step = game.steps.order(:number).last
      step_data = step.as_json
      %w[cards_chair_a cards_chair_b cards_chair_c cards_chair_d].each do |chair|
        step_data[chair] = (chair == "cards_#{player_chair}") ? step.send(chair) : []
      end

      # Adiciona o owner da sala ao JSON
      owner_data = { name: game.room.owner.name } if game.room.owner

      render json: game.as_json_with_chairs.merge(
        step: step_data,
        room_name: game.room.name,
        owner: owner_data  # Inclui o owner no JSON
      )
    else
      render json: { error: "Game not found" }, status: :not_found
    end
  end

  def play_move
    player_name = request.headers["name"]
    card = params[:card]
    coverup = ActiveModel::Type::Boolean.new.cast(params[:coverup])
    accept = ActiveModel::Type::Boolean.new.cast(params[:accept])
    collect = ActiveModel::Type::Boolean.new.cast(params[:collect])
    call = params[:call]

    # Verifica se já há 4 cartas na mesa
    step = @game.steps.order(:number).last
       if card && step.table_cards.size >= 4
        render json: { error: "Cannot play card, table already has 4 cards" }, status: :forbidden
        return
       end

      player_chair = find_player_chair(@game.room, player_name)
      unless player_chair
         render json: { error: "Player is not part of this game" }, status: :forbidden
        return
      end

    step = @game.steps.order(:number).last

    if collect
      handle_collect(step, player_chair)
    else

    if step.player_time != player_name
      render json: { error: "Not your turn" }, status: :forbidden
      return
    end

    if card && !step.send("cards_#{player_chair}").include?(card)
      render json: { error: "Invalid card or card not in player's hand" }, status: :unprocessable_entity
      return
    end


    Rails.logger.info "Player #{player_name} plays card: #{card}, coverup: #{coverup}, accept: #{accept}, call: #{call}"

    if call && ![ 3, 6, 9, 12 ].include?(call)
      render json: { error: "Invalid truco call" }, status: :unprocessable_entity
      return
    end

    # Move card to table_cards and remove it from player's hand
    step.table_cards << card
    step.update(table_cards: step.table_cards)
    player_cards = step.send("cards_#{player_chair}")
    player_cards.delete(card)
    step.update("cards_#{player_chair}" => player_cards)


    # Determine the team based on the player's chair
    player_chair_modified = player_chair.strip.upcase[-1]  # Pega a última letra de player_chair (A, B, etc.)
    puts "Valor ajustado de player_chair: #{player_chair}"  # Verifica o valor exato

    team = %w[A B].include?(player_chair_modified) ? "NOS" : "ELES"
    card_origin_record = "#{card}---#{player_chair}---#{team}---#{player_name}"
    puts "Resultado de card_origin_record: #{card_origin_record}"

# Save card origin in the first available column
if step.first_card_origin.nil?
  step.update(first_card_origin: card_origin_record)
elsif step.second_card_origin.nil?
  step.update(second_card_origin: card_origin_record)
elsif step.third_card_origin.nil?
  step.update(third_card_origin: card_origin_record)
elsif step.fourth_card_origin.nil?
  step.update(fourth_card_origin: card_origin_record)
end

# Se todas as quatro colunas de origem estiverem preenchidas, não definir o próximo jogador
if step.fourth_card_origin.nil?
  # Determine next player in sequence A -> D -> B -> C -> A
  chair_order = %w[A D B C]
  next_chair = chair_order[(chair_order.index(player_chair[-1].upcase) + 1) % chair_order.length]
  next_player_name = @game.room.send("chair_#{next_chair.downcase}")
  step.update(player_time: next_player_name)
end

# Determina o vencedor da rodada
determine_round_winner(step)

head :ok
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
    # Atualize o trecho abaixo
    if step.fourth_card_origin
      current_chair = step.fourth_card_origin.split("---")[1] # Extraindo "chair_a", "chair_b", etc.
      current_chair_letter = current_chair[-1].upcase # Obtendo apenas a letra da cadeira (A, B, C, D)

      # Ordem natural das cadeiras
      chair_order = %w[A D B C]

      # Encontrando a próxima cadeira na ordem natural
      next_chair = chair_order[(chair_order.index(current_chair_letter) + 1) % chair_order.length]

      # Definindo o próximo jogador
      next_player_name = @game.room.send("chair_#{next_chair.downcase}")
      step.update(first: "EMPACHE", player_time: next_player_name)
    else
      render json: { error: "Unable to determine next chair" }, status: :unprocessable_entity
      return
    end

    return # Finaliza a execução para evitar operações adicionais com `nil`
  end

  # Salva o vencedor no campo apropriado (first ou second), garantindo que strongest_card_origin não seja nil
  if step.first.nil?
    step.update(
      first: winner_team,
      player_time: strongest_card_origin&.split("---")&.fetch(3, nil) # Extrai o nome do jogador com a carta mais forte
    )
  else
    step.update(
      second: winner_team,
      player_time: strongest_card_origin&.split("---")&.fetch(3, nil) # Extrai o nome do jogador com a carta mais forte
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
  return [mania_played[:team], mania_played] if mania_played

  # Agrupando por equipe para determinar o maior valor em cada time
  teams = card_values.group_by { |entry| entry[:team] }
  max_nos_card = teams["NOS"]&.max_by { |entry| entry[:strength] }
  max_eles_card = teams["ELES"]&.max_by { |entry| entry[:strength] }

  # Determina empate caso as forças sejam iguais
  if max_nos_card && max_eles_card && max_nos_card[:strength] == max_eles_card[:strength]
    return ["EMPACHE", nil]
  end

  # Define o time vencedor com a carta mais forte
  winning_team = max_nos_card[:strength] > max_eles_card[:strength] ? "NOS" : "ELES"
  strongest_card = [max_nos_card, max_eles_card].compact.max_by { |entry| entry[:strength] }
  [winning_team, "#{strongest_card[:card]}---#{strongest_card[:chair]}---#{strongest_card[:team]}---#{strongest_card[:player_name]}"]
end

# Calcula a força de uma carta considerando a MANIA e hierarquia de naipes
def calculate_card_strength(card, mania_card, hierarchy, chair)
  # Hierarquia básica de força

  card_value = card[0..-2] # Remove o último caractere (naipe) da carta
  base_strength = hierarchy.index(card_value)
  Rails.logger.info "mania_card: #{mania_card}"
  Rails.logger.info "card: #{card}"
  Rails.logger.info "hierarchy: #{hierarchy}"
  Rails.logger.info "Base strength: #{base_strength}"
  # Se a carta for MANIA, ajuste a força com base no naipe
  if card_value == mania_card
    suit_order = %w[O E C Z]
    card_nipe = card[-1]
    base_strength = hierarchy.size + suit_order.index(card_nipe)
  end
  Rails.logger.info "Base strength: #{base_strength}"
  base_strength
end

def handle_collect(step, player_chair)
  step.update(
    table_cards: [],
    first_card_origin: nil,
    second_card_origin: nil,
    third_card_origin: nil,
    fourth_card_origin: nil
  )

  head :ok
end

  ####################################################################################################
end
