class Gamex2Service
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

    # Busca as mensagens do chat associado à sala do jogo
    chat = @game.room.chat
    messages = RoomService.fetch_recent_messages(chat)

    # Formata os dados do step para o jogador ou telespectador
    step_data = format_step_data(step, player_chair)

    # Monta o JSON no padrão esperado
    response_data = @game.as_json_with_chairs.merge(
      step: step_data,
      room_name: @game.room.name,
      owner: { name: @game.room.owner.name },
      messages: messages,
      is_two_players: @game.is_two_players,
      protected: @game.room.password.present?
    )

    response_data
  end

  def play_move(card, coverup)
    return { error: "Player is not part of this game", status: :forbidden } unless valid_player?

    if card
      return { error: "Cannot play card, table already has 4 cards", status: :forbidden } if @step.table_cards.size >= 2

      unless player_cards.include?(card)
        return { error: "Invalid card or card not in player's hand", status: :unprocessable_entity }
      end

      play_card(card, coverup)
    end

    {}
  end

  def collect(collect)
    return { error: "Invalid collect action", status: :unprocessable_entity } unless collect

    player_chair = find_player_chair
    return { error: "Player not part of this game", status: :forbidden } unless player_chair

    handle_collect(@step, player_chair)
  end

  def handle_call(call_value, accept)
    if call_value
      handle_truco_call(call_value)
    elsif [ true, false ].include?(accept)
      handle_accept_decision(accept)
    else
      { error: "Invalid call action", status: :unprocessable_entity }
    end
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

  def player_cards
    chair = find_player_chair
    @step.send("cards_#{chair}")
  end

  def play_card(card, coverup)
    chair = find_player_chair
    card_to_save = coverup ? "EC" : card

    # Atualiza as cartas na mesa
    @step.table_cards << card_to_save
    @step.update!(table_cards: @step.table_cards)

    # Remove a carta da mão do jogador
    updated_cards = @step.send("cards_#{chair}")
    updated_cards.delete(card)
    @step.update!("cards_#{chair}" => updated_cards)

    save_card_origin(card_to_save, chair)
    set_next_player(chair) if @step.fourth_card_origin.nil?

    # Determina vencedor da rodada e do jogo
    determine_round_winner
    determine_game_winner
  end

  def save_card_origin(card, chair)
    team = %w[A B].include?(chair.strip.upcase[-1]) ? "NOS" : "ELES"
    card_origin_record = "#{card}---#{chair}---#{team}---#{@player_name}"

    %i[first_card_origin second_card_origin third_card_origin fourth_card_origin].each do |column|
      if @step.send(column).nil?
        @step.update!(column => card_origin_record)
        break
      end
    end
  end

  def set_next_player(current_chair)
    chair_order = %w[A C A C]

    # Extrai a letra da cadeira, caso esteja no formato 'chair_a'
    current_chair = current_chair[-1].upcase if current_chair.start_with?("chair_")

    # Verifica se a cadeira é válida
    unless chair_order.include?(current_chair)
      raise "Invalid chair: #{current_chair.inspect}"
    end

    # Determina a próxima cadeira
    next_chair = chair_order[(chair_order.index(current_chair) + 1) % chair_order.size]

    # Busca o próximo jogador baseado na cadeira
    next_player_name = @game.room.send("chair_#{next_chair.downcase}")

    # Verifica se o próximo jogador existe
    unless next_player_name
      raise "No player assigned to chair: #{next_chair}"
    end

    # Atualiza o próximo jogador no step
    @step.update!(player_time: next_player_name)
  end

  def determine_round_winner
    table_cards = @step.table_cards
    card_origins = [
      @step.first_card_origin,
      @step.second_card_origin
    ].compact

    # Verifica se há cartas suficientes para determinar o vencedor
    return if table_cards.size != 2 || card_origins.size != 2

    # Calcula o vencedor
    winner_team, strongest_card_origin = calculate_winner(table_cards, card_origins, @step.vira)

    if winner_team == "EMPACHE" || strongest_card_origin.nil?
      handle_empache
    else
      handle_winner(winner_team, strongest_card_origin)
    end
  end

  private

  def handle_empache
    if @step.first.nil?
      @step.update(first: "EMPACHE")
    elsif @step.second.nil?
      @step.update(second: "EMPACHE")
    end

    set_next_player_after_empache
  end

  def handle_winner(winner_team, strongest_card_origin)
    if @step.first.nil?
      @step.update(first: winner_team, player_time: extract_player_from_origin(strongest_card_origin))
    elsif @step.second.nil?
      @step.update(second: winner_team, player_time: extract_player_from_origin(strongest_card_origin))
    else
      @step.update(third: winner_team, player_time: extract_player_from_origin(strongest_card_origin))
    end
  end

  def set_next_player_after_empache
    last_card_origin = @step.second_card_origin || @step.first_card_origin
    current_chair = last_card_origin.split("---")[1]
    next_player_name = determine_next_player(current_chair)
    @step.update(player_time: next_player_name)
  end

  def extract_player_from_origin(card_origin)
    card_origin&.split("---")&.fetch(3, nil)
  end

  def determine_next_player(current_chair)
    chair_order = %w[A C A C]
    next_chair = chair_order[(chair_order.index(current_chair) + 1) % chair_order.size]
    @game.room.send("chair_#{next_chair.downcase}")
  end

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

  def determine_game_winner
    case
    when @step.first == "EMPACHE"
      if @step.second == "EMPACHE"
        @step.update(win: @step.third == "EMPACHE" ? "EMP" : @step.third)
      else
        @step.update(win: @step.second)
      end
    when @step.first && @step.second == "EMPACHE"
      @step.update(win: @step.first)
    when @step.first && @step.first == @step.second
      @step.update(win: @step.first)
    when @step.first && @step.first != @step.second && @step.second != "EMPACHE"
      @step.update(win: @step.third == "EMPACHE" ? @step.first : @step.third)
    when @step.first == "EMPACHE" && @step.second == "EMPACHE" && @step.third == "EMPACHE"
      @step.update(win: "EMP")
    end
  end

  def handle_collect(step, player_chair)
    if step.win && step.win != "EMPT"
      handle_winner_single(step)
    else
      step.update(
        table_cards: [],
        first_card_origin: nil,
        second_card_origin: nil,
        third_card_origin: nil,
        fourth_card_origin: nil
      )
      { message: "Cards cleared" }
    end
  end

  def handle_winner_single(step)
    game = step.game
    additional_points = calculate_additional_points(step)

    if step.win == "NOS"
      game.increment!(:score_us, additional_points)
    elsif step.win == "ELES"
      game.increment!(:score_them, additional_points)
    end

    winner = check_winner(game)
    if winner
      finalize_game(step, game, winner)
    else
      reset_step(step, Step.generate_deck.shuffle)
      if step.errors.any?
        { error: "Failed to reset round", details: step.errors.full_messages, status: :internal_server_error }
      else
        { message: "Point awarded and round reset", step_id: step.id }
      end
    end
  end

  def check_winner(game)
    return "NOS" if game.score_us >= 12
    return "ELES" if game.score_them >= 12
    nil
  end

  def finalize_game(step, game, winner)
    game.update(end_game_win: winner)
    step.update(
      table_cards: [],
      first_card_origin: nil,
      second_card_origin: nil,
      third_card_origin: nil,
      fourth_card_origin: nil,
      win: nil
    )
    game.room.update(game: nil)
    game.room.room_players.update_all(ready: false)
    { message: "Game finished. #{winner} won!", game_id: game.uuid }
  end

  def reset_step(step, deck)
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
  def calculate_additional_points(step)
    case
    when step.player_call_12.present?
      step.is_accept_second.include?("---yes") ? 12 : 9
    when step.player_call_9.present?
      step.is_accept_second.include?("---yes") ? 9 : 6
    when step.player_call_6.present?
      step.is_accept_second.include?("---yes") ? 6 : 3
    when step.player_call_3.present?
      step.is_accept_second.include?("---yes") ? 3 : 1
    else
      1
    end
  end

  def handle_truco_call(call_value)
    valid_calls = [ 3, 6, 9, 12 ]
    return { error: "Invalid truco call", status: :unprocessable_entity } unless valid_calls.include?(call_value.to_i)

    player_chair = find_player_chair
    return { error: "Player is not part of this game", status: :forbidden } unless player_chair

    team = %w[a b].include?(player_chair[-1].downcase) ? "NOS" : "ELES"
    player_call_value = "#{@player_name}---#{team}"

    step_column = case call_value.to_i
    when 3 then :player_call_3
    when 6 then :player_call_6
    when 9 then :player_call_9
    when 12 then :player_call_12
    end

    if @step.send(step_column).nil?
      @step.update(step_column => player_call_value, player_time: nil, is_accept_first: nil, is_accept_second: nil)
      { message: "Truco called at level #{call_value} by #{@player_name} (#{team})" }
    else
      { error: "Level #{call_value} already called", status: :unprocessable_entity }
    end
  end

  def handle_accept_decision(accept)
    player_chair = find_player_chair
    return { error: "Player is not part of this game", status: :forbidden } unless player_chair

    team = %w[a b].include?(player_chair[-1].downcase) ? "NOS" : "ELES"
    decision = "#{@player_name}---#{accept ? 'yes' : 'no'}---#{team}"

    # Verifica se o jogador já tomou uma decisão anteriormente
    existing_decisions = [ @step.is_accept_first, @step.is_accept_second ].compact
    if existing_decisions.any? { |d| d.split("---").first == @player_name }
      return { error: "Player already made a decision", status: :unprocessable_entity }
    end

    # Salva a decisão como "second" e resolve
    if @step.is_accept_second.nil?
      @step.update(is_accept_second: decision)
      resolve_truco_decision
    else
      { error: "Both decisions already made", status: :unprocessable_entity }
    end
  end

  def resolve_truco_decision
    last_truco_call = [
      @step.player_call_3,
      @step.player_call_6,
      @step.player_call_9,
      @step.player_call_12
    ].compact.first

    return { error: "No truco call to resolve", status: :unprocessable_entity } unless last_truco_call

    player_data = last_truco_call.split("---")
    truco_player = player_data[0]
    truco_team = player_data[1]

    if @step.is_accept_second.include?("---no")
      losing_team = @step.is_accept_second.split("---").last # Extract the team that refused
      winning_team = losing_team == "NOS" ? "ELES" : "NOS" # Opposite team wins
      @step.update!(win: winning_team, player_time: truco_player)
      { message: "Truco rejected, #{truco_team} wins the point. Next turn: #{truco_player}" }

    elsif @step.is_accept_second.include?("---yes")
      if @step.table_cards.any? || [
        @step.first_card_origin,
        @step.second_card_origin,
        @step.third_card_origin,
        @step.fourth_card_origin
      ].any?
        last_card_origin = [
          @step.fourth_card_origin,
          @step.third_card_origin,
          @step.second_card_origin,
          @step.first_card_origin
        ].compact.first

        if last_card_origin
          last_player_chair = last_card_origin.split("---")[1]
          chair_order = %w[A C A C]
          next_chair = chair_order[(chair_order.index(last_player_chair[-1].upcase) + 1) % chair_order.length]
          next_player_name = @game.room.send("chair_#{next_chair.downcase}")
          @step.update!(player_time: next_player_name)
          { message: "Truco accepted, next player is #{next_player_name}" }
        else
          { error: "Error determining the next player", status: :internal_server_error }
        end
      else
        @step.update!(player_time: truco_player)
        { message: "Truco accepted, turn remains with #{truco_player}" }
      end
    else
      { error: "Invalid truco decision state", status: :unprocessable_entity }
    end
  end
end
