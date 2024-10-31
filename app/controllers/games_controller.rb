class GamesController < ApplicationController
    before_action :authenticate_player, only: [:show]
    before_action :set_game, only: [:show]
  
    def show
        game = Game.find_by(uuid: params[:uuid])
        
        if game
          step = game.steps.order(:number).last  # Pega o último passo ou cria um novo se for a primeira etapa
          render json: game.as_json_with_chairs.merge(step: step.as_json)
        else
          render json: { error: 'Game not found' }, status: :not_found
        end
      end
  
    private
  
    def set_game
      @game = Game.find_by(uuid: params[:uuid])
    end
  end
  