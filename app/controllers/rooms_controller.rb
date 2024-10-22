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
          # Verificar se o jogador já está na sala
          player = Player.find_by(uuid: params[:player_uuid])
          if player
            if room.players.exists?(player.id)
              render json: { error: "Player is already in the room" }, status: :unprocessable_entity
            else
              # Calcular o número atual de jogadores na sala
              current_players_count = room.players.count
      
              if current_players_count < 4
                # Adicionar o jogador à sala
                RoomPlayer.create(room: room, player: player)
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
          # Verificar se o jogador está na sala
          if room.players.exists?(player.id)
            if room.owner == player
              # Se o owner sair da sala, a sala deve ser deletada
              room.destroy
              render json: { message: "Room removed" }, status: :ok
            else
              # Remover o jogador da sala
              room_player = RoomPlayer.find_by(room: room, player: player)
              room_player.destroy if room_player
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
        room = Room.find_by(uuid: params[:id]) # Usamos params[:id] pois o Rails usa esse padrão para rotas show
    
        if room
          render json: room.as_json.merge(players_count: room.players.count)
        else
          render json: { error: "Room not found" }, status: :not_found
        end
      end
  
    private
  
    def room_params
      params.require(:room).permit(:name)
    end
  end
  