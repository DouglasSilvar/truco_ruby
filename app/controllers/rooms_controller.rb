class RoomsController < ApplicationController
  skip_before_action :authenticate_player, only: [ :index, :show ]

  def index
    result = RoomService.list_rooms(page: params[:page], per_page: params[:per_page] || 10)
    render json: result
  end

  def show
    result = RoomService.show_room_details(
      room_id: params[:id],
      player_uuid: request.headers["uuid"]
    )

    if result[:success]
      render json: result[:room].as_json.merge(
        players_count: result[:players_count],
        chairs: result[:chairs],
        player_kick_status: result[:player_kick_status],
        ready: result[:ready],
        messages: result[:messages]
      )
    else
      render json: { error: result[:error] }, status: :not_found
    end
  end

  def create
    # Captura os parâmetros diretamente do payload
    player_uuid = params[:player_uuid]
    room_params = {
      name: params.dig(:room, :name), # Captura o nome da sala dentro da chave "room"
      password: params[:password] # Captura a senha diretamente
    }

    # Chama o serviço passando os parâmetros
    result = RoomService.create_room(params: room_params, player_uuid: player_uuid)

    # Renderiza o resultado
    if result[:success]
      render json: result[:room].as_json.merge(players_count: result[:room].room_players.where(kick: false).count), status: :created
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end


  def join_room
    result = RoomService.join_room(
      room_uuid: params[:uuid],
      player_uuid: params[:player_uuid],
      password: params[:password]
    )

    if result[:success]
      render json: { message: result[:message], room: result[:room].as_json.merge(players_count: result[:room].room_players.where(kick: false).count) }, status: :ok
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def leave_room
    result = RoomService.leave_room(
      room_uuid: params[:uuid],
      player_uuid: params[:player_uuid]
    )

    if result[:success]
      render json: { message: result[:message] }, status: :ok
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def change_chair
    result = RoomService.change_chair(
      room_uuid: params[:uuid],
      player_name: params[:player_name],
      chair_destination: params[:chair_destination]
    )

    if result[:success]
      render json: { message: result[:message] }, status: :ok
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def kick_player
    result = RoomService.kick_player(
      room_uuid: params[:uuid],
      player_name: params[:player_name],
      owner_uuid: request.headers["uuid"]
    )

    if result[:success]
      render json: { message: result[:message], room: result[:room] }, status: :ok
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def start_game
    result = RoomService.start_game(
      room_uuid: params[:uuid],
      player_uuid: request.headers["uuid"]
    )

    if result[:success]
      render json: result, status: :ok
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def update_ready_status
    result = RoomService.update_ready_status(
      room_uuid: params[:uuid],
      player_uuid: request.headers["uuid"],
      ready: params[:boolean]
    )

    if result[:success]
      render json: { message: result[:message], ready: result[:ready] }, status: :ok
    else
      render json: { error: result[:error], details: result[:details] }, status: :unprocessable_entity
    end
  end

  def send_message
    result = RoomService.send_message(
      room_uuid: params[:uuid],
      player_uuid: request.headers["uuid"],
      content: params[:content]
    )

    if result[:success]
      render json: { message: result[:message] }, status: :created
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end
end
