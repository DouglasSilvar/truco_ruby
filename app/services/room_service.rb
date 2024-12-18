# app/services/room_service.rb
class RoomService
  def self.list_rooms(page:, per_page: 10)
    rooms = Room.page(page).per(per_page)
    rooms_with_players_count = rooms.map do |room|
      room.as_json.merge(players_count: room.room_players.where(kick: false).count)
    end

    {
      rooms: rooms_with_players_count,
      meta: {
        current_page: rooms.current_page,
        next_page: rooms.next_page,
        prev_page: rooms.prev_page,
        total_pages: rooms.total_pages,
        total_count: rooms.total_count
      }
    }
  end

  def self.show_room_details(room_id:, player_uuid:)
    room = Room.find_by(uuid: room_id)
    return { success: false, error: "Room not found" } unless room

    player = Player.find_by(uuid: player_uuid)

    # Busca as mensagens do chat associado à sala
    # Verifica se o jogador está na sala (nas cadeiras)
    player_in_room = %w[chair_a chair_b chair_c chair_d].any? { |chair| room[chair] == player&.name }

    # Busca as mensagens do chat apenas se o jogador estiver na sala e for válido
    chat = room.chat
    messages = player && player_in_room ? RoomService.fetch_recent_messages(chat) : nil

    chairs = {
      chair_a: room.chair_a,
      chair_b: room.chair_b,
      chair_c: room.chair_c,
      chair_d: room.chair_d
    }

    # Buscar todos os jogadores prontos
    ready_players = room.room_players.includes(:player).where(ready: true, kick: false).map do |room_player|
      { player: room_player.player.name }
    end

    # Adicionar o owner como pronto
    owner_player = room.owner
    ready_players << { player: owner_player.name } unless ready_players.any? { |p| p[:player] == owner_player.name }

    players_count = room.room_players.where(kick: false).count

    if player
      room_player = RoomPlayer.find_by(room: room, player: player)
      player_kick_status = room_player&.kick

      {
        success: true,
        room: room,
        players_count: players_count,
        chairs: chairs,
        player_kick_status: player_kick_status,
        ready: ready_players,
        messages: messages
      }
    else
      # Jogador não encontrado, mas retorna informações da sala
      {
        success: true,
        room: room,
        players_count: players_count,
        chairs: chairs,
        player_kick_status: nil,
        ready: ready_players,
        messages: messages
      }
    end
  end

  def self.create_room(params:, player_uuid:)
    player = Player.find_by(uuid: player_uuid)

    return { success: false, error: "Player not found" } unless player
    room = Room.new(params)
    room.owner = player
    room.password = params[:password] if params[:password].present? # Persiste o password caso exista

    if room.save
      RoomPlayer.create(room: room, player: player)
      room.update(chair_a: player.name)

      { success: true, room: room }
    else
      { success: false, error: room.errors.full_messages }
    end
  end

  def self.join_room(room_uuid:, player_uuid:, password:)
    room = Room.find_by(uuid: room_uuid)
    return { success: false, error: "Room not found" } unless room

    if room.password.present? && room.password != password
      return { success: false, error: "Invalid password" }
    end

    player = Player.find_by(uuid: player_uuid)
    return { success: false, error: "Player not found" } unless player

    room_player = RoomPlayer.find_by(room: room, player: player)

    if room_player
      if room_player.kick
        room_player.update(kick: false)
        room.assign_random_chair(player.name)
        return { success: true, message: "Player rejoined the room", room: room }
      else
        return { success: false, error: "Player is already in the room" }
      end
    end

    if room.players.count < 4
      RoomPlayer.create(room: room, player: player)
      room.assign_random_chair(player.name)
      { success: true, message: "Player joined the room", room: room }
    else
      { success: false, error: "Room is full" }
    end
  end

  def self.leave_room(room_uuid:, player_uuid:)
    room = Room.find_by(uuid: room_uuid)
    player = Player.find_by(uuid: player_uuid)

    return { success: false, error: "Room or Player not found" } unless room && player

    if room.players.exists?(player.id)
      if room.owner == player
        room.room_players.destroy_all
        room.games.destroy_all
        room.destroy
        { success: true, message: "Room removed" }
      else
        room_player = RoomPlayer.find_by(room: room, player: player)
        room_player.destroy if room_player
        room.remove_player_from_chair(player.name)
        { success: true, message: "Player left the room", room: room }
      end
    else
      { success: false, error: "Player is not in the room" }
    end
  end

  def self.change_chair(room_uuid:, player_name:, chair_destination:)
    room = Room.find_by(uuid: room_uuid)
    return { success: false, error: "Room not found" } unless room

    player_chair = %w[chair_a chair_b chair_c chair_d].find { |chair| room[chair] == player_name }
    return { success: false, error: "Player is not in the room" } unless player_chair

    if room[chair_destination].present?
      return { success: false, error: "Chair #{chair_destination} is already occupied" }
    end

    room[chair_destination] = player_name
    room[player_chair] = nil
    room.save
    { success: true, message: "Player #{player_name} moved to #{chair_destination}" }
  end

  def self.update_ready_status(room_uuid:, player_uuid:, ready:)
    room = Room.find_by(uuid: room_uuid)
    return { success: false, error: "Room not found" } unless room

    player = Player.find_by(uuid: player_uuid)
    return { success: false, error: "Player not found" } unless player

    room_player = RoomPlayer.find_by(room: room, player: player)
    return { success: false, error: "Player not in room" } unless room_player

    if room_player.update(ready: ready)
      { success: true, message: "Ready status updated", ready: room_player.ready }
    else
      { success: false, error: "Failed to update ready status", details: room_player.errors.full_messages }
    end
  end

  def self.kick_player(room_uuid:, player_name:, owner_uuid:)
    room = Room.find_by(uuid: room_uuid)
    return { success: false, error: "Room not found" } unless room

    # Verificação do dono da sala
    owner = Player.find_by(uuid: owner_uuid)
    return { success: false, error: "Unauthorized: Player not found" } unless owner
    return { success: false, error: "Only the room owner can kick players" } unless room.owner == owner

    # Verificar se o jogador está na sala
    player_to_kick = Player.find_by(name: player_name)
    room_player = RoomPlayer.find_by(room: room, player: player_to_kick)

    if room_player
      room_player.update(kick: true, ready: false) # Marcar o jogador como expulso e 'ready' como false
      room.remove_player_from_chair(player_to_kick.name) # Remover o jogador da cadeira
      {
        success: true,
        message: "#{player_to_kick.name} has been kicked from the room",
        room: room.as_json.merge(players_count: room.room_players.where(kick: false).count)
      }
    else
      { success: false, error: "Player not found in the room" }
    end
  end

  def self.start_game(room_uuid:, player_uuid:)
    room = Room.find_by(uuid: room_uuid)
    return { success: false, error: "Room not found" } unless room

    # Verifica se o solicitante é o owner da sala
    if room.owner.uuid != player_uuid
      return { success: false, error: "Only the room owner can start the game" }
    end

    # Verifica o número de jogadores prontos, excluindo o owner
    ready_players_count = room.room_players.where.not(player_id: room.owner.uuid)
                                           .where(ready: true, kick: false).count

    if ready_players_count != 3
      return { success: false, error: "Game cannot be started. There must be 3 players ready, excluding the owner." }
    end

    # Inicia o jogo e cria o UUID
    game_id = SecureRandom.uuid
    room.update(game: game_id)

    # Criar a entrada na tabela de jogos e verificar sucesso
    game = Game.new(uuid: game_id, room_id: room.uuid)
    return { success: false, error: game.errors.full_messages } unless game.save

    # Gera o baralho completo e distribui as cartas
    deck = Step.generate_deck.shuffle
    cards_chair_a, cards_chair_b, cards_chair_c, cards_chair_d = deck.shift(3), deck.shift(3), deck.shift(3), deck.shift(3)
    vira = deck.shift # Define a carta 'vira' aleatoriamente

    step = Step.new(
      game_id: game.uuid,
      number: 1,
      cards_chair_a: cards_chair_a,
      cards_chair_b: cards_chair_b,
      cards_chair_c: cards_chair_c,
      cards_chair_d: cards_chair_d,
      table_cards: [],
      vira: vira,
      player_time: room.chair_a
    )

    if step.save
      { success: true, message: "Game started", game_id: game_id, step_id: step.id }
    else
      { success: false, error: step.errors.full_messages }
    end
  end

  def self.send_message(room_uuid:, player_uuid:, content:)
    room = Room.find_by(uuid: room_uuid)
    return { success: false, error: "Room not found" } unless room

    player = Player.find_by(uuid: player_uuid)
    return { success: false, error: "Player not found" } unless player

    # Verifica se o jogador está na sala
    unless room.players.include?(player)
      return { success: false, error: "Player is not part of this room" }
    end

    # Verifica o comprimento do conteúdo
    if content.blank? || content.length > 256
      return { success: false, error: "Message content must be between 1 and 256 characters" }
    end

    # Cria a mensagem
    chat = room.chat
    message = chat.messages.create(player_id: player.uuid, content: content)

    if message.persisted?
      { success: true, message: "Message sent successfully" }
    else
      { success: false, error: "Failed to send message", details: message.errors.full_messages }
    end
  end
  def self.fetch_recent_messages(chat)
    chat.messages.order(created_at: :desc).limit(12).map do |message|
      {
        player_name: message.player.name,
        date_created: message.created_at.strftime("%Y-%m-%d %H:%M:%S"),
        content: message.content
      }
    end
  end

  def self.update_two_player_mode(room_uuid:, player_uuid:, two_player:)
    room = Room.find_by(uuid: room_uuid)
    return { success: false, error: "Room not found" } unless room

    # Verifica se o player que fez a solicitação é o dono da sala
    return { success: false, error: "Unauthorized" } unless room.owner.uuid == player_uuid

    new_value = ActiveRecord::Type::Boolean.new.cast(two_player)
    if room.update(is_two_players: new_value)
      { success: true, message: "Room updated successfully", is_two_players: room.is_two_players }
    else
      { success: false, error: "Failed to update room" }
    end
  end
end
