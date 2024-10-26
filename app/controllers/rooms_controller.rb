class RoomsController < ApplicationController

  skip_before_action :authenticate_player, only: [:index]

  def index
    rooms = Room.page(params[:page]).per(10)

    # Adicionar a contagem de jogadores em cada sala
    rooms_with_players_count = rooms.map do |room|
      room.as_json.merge(players_count: room.players.count)
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
      
        if room.save
          # Adiciona o jogador à sala através da tabela de associação
          RoomPlayer.create(room: room, player: player)
          
          # Colocar automaticamente o criador na cadeira A (usando o nome)
          room.update(chair_a: player.name)
      
          render json: room.as_json.merge(players_count: room.players.count), status: :created
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
        player = Player.find_by(uuid: params[:player_uuid])
        if player
          if room.players.exists?(player.id)
            render json: { error: "Player is already in the room" }, status: :ok
          else
            current_players_count = room.players.count
    
            if current_players_count < 4
              RoomPlayer.create(room: room, player: player)
              
              # Atribuir uma cadeira aleatória corretamente usando o nome do jogador
              room.assign_random_chair(player.name)
              
              render json: { message: "Player joined the room", room: room.as_json.merge(players_count: room.players.count) }, status: :ok
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
            room.destroy
            render json: { message: "Room removed" }, status: :ok
          else
            room_player = RoomPlayer.find_by(room: room, player: player)
            room_player.destroy if room_player
    
            # Remover o jogador da cadeira usando o nome
            room.remove_player_from_chair(player.name)
    
            render json: { message: "Player left the room", room: room.as_json.merge(players_count: room.players.count) }, status: :ok
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
        chairs = {
          chair_a: room.chair_a,
          chair_b: room.chair_b,
          chair_c: room.chair_c,
          chair_d: room.chair_d
        }
    
        render json: room.as_json.merge(players_count: room.players.count, chairs: chairs)
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
  
    private

    def find_player_chair(room, player_name)
      %w[chair_a chair_b chair_c chair_d].find { |chair| room[chair] == player_name }
    end
    def room_params
      params.require(:room).permit(:name)
    end
  end
  