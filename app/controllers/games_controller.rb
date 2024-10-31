class GamesController < ApplicationController
    before_action :authenticate_player, only: [:show]
    before_action :set_game, only: [:show]
  
    def show
        game = Game.find_by(uuid: params[:uuid])
        if game
          render json: game.as_json_with_chairs
        else
          render json: { error: "Game not found" }, status: :not_found
        end
      end
  
    private
  
    def set_game
      @game = Game.find_by(uuid: params[:uuid])
    end
  end
  