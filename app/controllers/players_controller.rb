class PlayersController < ApplicationController
    def index
      # Paginação com Kaminari
      players = Player.page(params[:page]).per(params[:per_page] || 10) # Tamanho padrão: 10 por página
      render json: {
        players: players.as_json(only: [:uuid, :name]),
        meta: {
          current_page: players.current_page,
          next_page: players.next_page,
          prev_page: players.prev_page,
          total_pages: players.total_pages,
          total_count: players.total_count
        }
      }
    end
  
    def create
        player = Player.new(player_params)  # Apenas o 'name' será passado como parâmetro
        if player.save
          render json: { uuid: player.uuid, name: player.name }, status: :created
        else
          render json: { error: player.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def validate_player
        player_name = request.headers['name']
        player_uuid = request.headers['uuid']
      
        if player_name.present? && player_uuid.present?
          player = Player.find_by(name: player_name, uuid: player_uuid)
          if player
            head :ok  # Retorna 200 OK sem body
          else
            head :not_found  # Retorna 404 Not Found
          end
        else
          head :bad_request  # Retorna 400 Bad Request se os headers estiverem faltando
        end
      end
  
    private
  
    def player_params
        params.require(:player).permit(:name)  # Apenas o 'name' está sendo permitido
      end
  end
  