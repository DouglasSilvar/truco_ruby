class RoomsController < ApplicationController
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
          
          # Colocar automaticamente o criador na cadeira A
          room.update(chair_a: player.uuid)
    
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
              
              # Atribuir uma cadeira aleatória corretamente
              room.assign_random_chair(player.uuid)
              
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
    
            # Remover o jogador da cadeira
            room.remove_player_from_chair(player.uuid)
    
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
  
    private
  
    def room_params
      params.require(:room).permit(:name)
    end
  end
  