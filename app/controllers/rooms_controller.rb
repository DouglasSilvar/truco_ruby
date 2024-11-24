class RoomsController < ApplicationController
  before_action :set_room, only: [ :kick_player, :start_game ]
  skip_before_action :authenticate_player, only: [:index, :show]

  def index
    rooms = Room.page(params[:page]).per(10)

    # Adicionar a contagem de jogadores em cada sala
    rooms_with_players_count = rooms.map do |room|
      room.as_json.merge(players_count: room.room_players.where(kick: false).count)
    end

    render json: {
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

  def create
    player_uuid = params[:player_uuid]

    # Verifique se o player existe
    player = Player.find_by(uuid: player_uuid)

    if player
      # Se o jogador existe, crie a sala
      room = Room.new(room_params)
      room.owner = player # Atribui o dono da sala como o jogador

      if params[:password].present?
        room.password = params[:password]
      end

      if room.save
        # Adiciona o jogador à sala através da tabela de associação
        RoomPlayer.create(room: room, player: player)

        # Colocar automaticamente o criador na cadeira A (usando o nome)
        room.update(chair_a: player.name)

        render json: room.as_json.merge(players_count: room.room_players.where(kick: false).count), status: :created
      else
        render json: room.errors, status: :unprocessable_entity
      end
    else
      # Se o jogador não existir, retorne um erro
      render json: { error: "Player not found" }, status: :not_found
    end
  end



  def join_room
    room = Room.find_by(uuid: params[:uuid])

    if room
      # Verificar se a sala requer uma senha e se a senha fornecida está correta
      if room.password.present? && room.password != params[:password]
        render json: { error: "Invalid password" }, status: :forbidden
        return
      end

      player = Player.find_by(uuid: params[:player_uuid])

      if player
        room_player = RoomPlayer.find_by(room: room, player: player)

        if room_player
          if room_player.kick
            # Se o jogador foi expulso antes, reinicie o status de kick para false
            room_player.update(kick: false)
            # Atribuir uma cadeira aleatória corretamente usando o nome do jogador
            room.assign_random_chair(player.name)
            render json: { message: "Player rejoined the room after being kicked", room: room.as_json.merge(players_count: room.room_players.where(kick: false).count) }, status: :ok
          else
            render json: { error: "Player is already in the room" }, status: :ok
          end
        else
          current_players_count = room.players.count

          if current_players_count < 4
            # Criar uma nova associação RoomPlayer
            RoomPlayer.create(room: room, player: player)
            # Atribuir uma cadeira aleatória corretamente usando o nome do jogador
            room.assign_random_chair(player.name)

            render json: { message: "Player joined the room", room: room.as_json.merge(players_count: room.room_players.where(kick: false).count) }, status: :ok
          else
            render json: { error: "Room is full" }, status: :unprocessable_entity
          end
        end
      else
        render json: { error: "Player not found" }, status: :not_found
      end
    else
      render json: { error: "Room not found" }, status: :not_found
    end
  end




  def leave_room
    room = Room.find_by(uuid: params[:uuid])
    player = Player.find_by(uuid: params[:player_uuid])

    if room && player
      if room.players.exists?(player.id)
        if room.owner == player
          # Remover manualmente os registros associados
          room.room_players.destroy_all
          room.games.destroy_all
          room.destroy
          render json: { message: "Room removed" }, status: :ok
        else
          room_player = RoomPlayer.find_by(room: room, player: player)
          room_player.destroy if room_player

          # Remover o jogador da cadeira usando o nome
          room.remove_player_from_chair(player.name)

          render json: { message: "Player left the room", room: room.as_json.merge(players_count: room.room_players.where(kick: false).count) }, status: :ok
        end
      else
        render json: { error: "Player is not in the room" }, status: :unprocessable_entity
      end
    else
      render json: { error: "Room or Player not found" }, status: :not_found
    end
  end

    def show
      room = Room.find_by(uuid: params[:id])

      if room
        # Recupera o jogador que fez a requisição a partir dos headers
        player_uuid = request.headers["uuid"]
        player = Player.find_by(uuid: player_uuid)

        chairs = {
          chair_a: room.chair_a,
          chair_b: room.chair_b,
          chair_c: room.chair_c,
          chair_d: room.chair_d
        }

        # Buscar todos os jogadores que estão prontos (ready: true) na sala
        ready_players = room.room_players.includes(:player).where(ready: true, kick: false).map do |room_player|
          { player: room_player.player.name }
        end

        # Garantir que o owner da sala está sempre com ready = true
        owner_player = room.owner
        ready_players << { player: owner_player.name } unless ready_players.any? { |p| p[:player] == owner_player.name }

        # Ajustar a contagem de jogadores excluindo os kickados
        players_count = room.room_players.where(kick: false).count

        # Se o jogador foi encontrado, verificar se está na sala
        if player
          room_player = RoomPlayer.find_by(room: room, player: player)

          if room_player
            # Jogador está na sala, incluir status de 'kick' e jogadores prontos
            render json: room.as_json.merge(
              players_count: players_count,  # Inclui a contagem sem os kickados
              chairs: chairs,
              player_kick_status: room_player.kick,  # Inclui o status do jogador na resposta
              ready: ready_players  # Inclui a lista de jogadores prontos, incluindo o owner
            )
          else
            # Jogador não está na sala, mas renderiza as informações da sala mesmo assim
            render json: room.as_json.merge(
              players_count: players_count,  # Inclui a contagem sem os kickados
              chairs: chairs,
              player_kick_status: nil,  # Jogador não está na sala, status 'kick' é nulo
              ready: ready_players  # Inclui a lista de jogadores prontos, incluindo o owner
            )
          end
        else
          # Jogador não foi encontrado, mas renderiza as informações da sala
          render json: room.as_json.merge(
            players_count: players_count,  # Inclui a contagem sem os kickados
            chairs: chairs,
            player_kick_status: nil,  # Jogador não foi encontrado, status 'kick' é nulo
            ready: ready_players  # Inclui a lista de jogadores prontos, incluindo o owner
          )
        end
      else
        render json: { error: "Room not found" }, status: :not_found
      end
    end





    def change_chair
      room = Room.find_by(uuid: params[:uuid])
      player_name = params[:player_name]
      chair_destination = params[:chair_destination]

      if room.nil?
        render json: { error: "Room not found" }, status: :not_found
        return
      end

      # Verifica se o player está na sala
      player_chair = find_player_chair(room, player_name)
      if player_chair.nil?
        render json: { error: "Player is not in the room" }, status: :unprocessable_entity
        return
      end

      # Verifica se a cadeira destino está disponível
      if room[chair_destination].present?
        render json: { error: "Chair #{chair_destination} is already occupied" }, status: :unprocessable_entity
        return
      end

      # Mover o jogador para a cadeira destino e liberar a cadeira antiga
      room[chair_destination] = player_name
      room[player_chair] = nil
      room.save

      render json: { message: "Player #{player_name} moved to #{chair_destination}" }, status: :ok
    end

    def kick_player
      player_name = params[:player_name]
      owner_name = request.headers["name"]
      owner_uuid = request.headers["uuid"]

      # Verificação do dono da sala (já existente)
      owner = Player.find_by(name: owner_name, uuid: owner_uuid)
      if owner.nil?
        render json: { error: "Unauthorized: Player not found" }, status: :unauthorized
        return
      end

      # Verificar se o jogador está na sala
      player_to_kick = Player.find_by(name: player_name)
      room_player = RoomPlayer.find_by(room: @room, player: player_to_kick)

      if room_player
        room_player.update(kick: true, ready: false) # Marcar o jogador como expulso e 'ready' como false
        @room.remove_player_from_chair(player_to_kick.name) # Remover o jogador da cadeira

        render json: { message: "#{player_to_kick.name} has been kicked from the room", room: @room.as_json.merge(players_count: @room.room_players.where(kick: false).count) }, status: :ok
      else
        render json: { error: "Player not found in the room" }, status: :unprocessable_entity
      end
    end


    def update_ready_status
      room = Room.find_by(uuid: params[:uuid])
      player = Player.find_by(uuid: request.headers["uuid"])

      if room && player
        room_player = RoomPlayer.find_by(room: room, player: player)

        if room_player
          room_player.update(ready: params[:boolean])
          render json: { message: "Ready status updated", ready: room_player.ready }, status: :ok
        else
          render json: { error: "Player not in room" }, status: :unprocessable_entity
        end
      else
        render json: { error: "Room or player not found" }, status: :not_found
      end
    end

    def start_game
      player_uuid = request.headers["uuid"]

      # Verifica se a sala existe
      if @room.nil?
        render json: { error: "Room not found" }, status: :not_found
        return
      end

      # Verifica se o solicitante é o owner da sala
      if @room.owner.uuid != player_uuid
        render json: { error: "Only the room owner can start the game" }, status: :forbidden
        return
      end

      # Verifica o número de jogadores prontos, excluindo o owner
      ready_players_count = @room.room_players.where.not(player_id: @room.owner.uuid).where(ready: true, kick: false).count

      if ready_players_count != 3
        render json: { error: "Game cannot be started. There must be 3 players ready, excluding the owner." }, status: :unprocessable_entity
        return
      end

      # Inicia o jogo e cria o UUID
      game_id = SecureRandom.uuid
      @room.update(game: game_id)

      # Criar a entrada na tabela de jogos e verificar sucesso
      game = Game.new(uuid: game_id, room_id: @room.uuid)
      if game.save
        # Distribuir 3 cartas para cada jogador e definir a 'vira'
        cards_chair_a, cards_chair_b, cards_chair_c, cards_chair_d = deck.shift(3), deck.shift(3), deck.shift(3), deck.shift(3)
        vira = deck.shift # Define a carta 'vira' aleatoriamente

        # Criar o primeiro step para o jogo
        step = Step.new(
          game_id: game.uuid,
          number: 1,
          cards_chair_a: cards_chair_a,
          cards_chair_b: cards_chair_b,
          cards_chair_c: cards_chair_c,
          cards_chair_d: cards_chair_d,
          table_cards: [],
          vira: vira,
          player_time: @room.chair_a
        )
        if step.save
          render json: { message: "Game started", game_id: game_id, step_id: step.id }, status: :ok
        else
          render json: { error: "Failed to create initial step", details: step.errors.full_messages }, status: :internal_server_error
        end
      else
        render json: { error: "Failed to create game record", details: game.errors.full_messages }, status: :internal_server_error
      end
    end


    private

    def set_room
      @room = Room.find_by(uuid: params[:uuid])
      unless @room
        render json: { error: "Room not found" }, status: :not_found
      end
    end

    def find_player_chair(room, player_name)
      %w[chair_a chair_b chair_c chair_d].find { |chair| room[chair] == player_name }
    end
    def room_params
      params.require(:room).permit(:name, :password)
    end
end
