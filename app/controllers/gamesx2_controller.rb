class Gamesx2Controller < ApplicationController
  before_action :authenticate_player, only: [ :show, :play_move ]
  before_action :set_game, only: [ :show, :play_move, :call, :collect ]

  def show
    player_name = request.headers["name"]
    service = Gamex2Service.new(@game, player_name)
    result = service.show_game
    if result[:error]
      render json: { error: result[:error] }, status: result[:status]
    else
      render json: result
    end
  end

  def play_move
    card = params[:card]
    coverup = ActiveModel::Type::Boolean.new.cast(params[:coverup])
    player_name = request.headers["name"]

    service = Gamex2Service.new(@game, player_name)
    result = service.play_move(card, coverup)

    if result[:error]
      render json: { error: result[:error] }, status: result[:status]
    else
      head :ok
    end
  end

def call
  accept = ActiveModel::Type::Boolean.new.cast(params[:accept])
  call_value = params[:call]
  player_name = request.headers["name"]

  service = Gamex2Service.new(@game, player_name)
  result = service.handle_call(call_value, accept)

  if result[:error]
    render json: { error: result[:error] }, status: result[:status]
  else
    render json: result[:message], status: :ok
  end
end

  def collect
    collect = ActiveModel::Type::Boolean.new.cast(params[:collect])
    player_name = request.headers["name"]

    service = Gamex2Service.new(@game, player_name)
    result = service.collect(collect)

    if result[:error]
      render json: { error: result[:error] }, status: result[:status]
    else
      render json: result[:message], status: :ok
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
end
