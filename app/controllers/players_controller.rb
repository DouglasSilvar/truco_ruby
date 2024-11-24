class PlayersController < ApplicationController
  def index
    result = PlayerService.paginated_players(
      page: params[:page],
      per_page: params[:per_page] || 10
    )
    render json: result
  end

  def create
    result = PlayerService.create_player(player_params)
    if result[:success]
      render json: result[:player].as_json_with_player_id, status: :created
    else
      render json: { error: result[:errors] }, status: :unprocessable_entity
    end
  end

  def validate_player
    player_name = request.headers["name"]
    player_uuid = request.headers["uuid"]

    if player_name.present? && player_uuid.present?
      if PlayerService.validate_player(name: player_name, uuid: player_uuid)
        head :ok
      else
        head :not_found
      end
    else
      head :bad_request
    end
  end

  private

  def player_params
    params.require(:player).permit(:name)
  end
end
