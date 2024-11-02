class GamesController < ApplicationController
  before_action :authenticate_player, only: [:show, :play_move]
  before_action :set_game, only: [:show, :play_move]
  
  def show
    player_name = request.headers['name']
    game = Game.find_by(uuid: params[:uuid])

    if game
      # Verificar se o jogador pertence à sala e identificar a cadeira
      player_chair = find_player_chair(game.room, player_name)
      unless player_chair
        render json: { error: "Player is not part of this game" }, status: :forbidden
        return
      end

      # Pegar o último passo do jogo
      step = game.steps.order(:number).last

      # Construir a resposta JSON com cartas vazias para as cadeiras que não pertencem ao jogador
      step_data = step.as_json
      %w[cards_chair_a cards_chair_b cards_chair_c cards_chair_d].each do |chair|
        step_data[chair] = (chair == "cards_#{player_chair}") ? step.send(chair) : []
      end

      # Montar a resposta final com as cartas filtradas
      render json: game.as_json_with_chairs.merge(step: step_data)
    else
      render json: { error: 'Game not found' }, status: :not_found
    end
  end
      def play_move
        player_name = request.headers['name']
        card = params[:card]
        coverup = ActiveModel::Type::Boolean.new.cast(params[:coverup]) # Encobre ou não
        accept = ActiveModel::Type::Boolean.new.cast(params[:accept])   # Aceita a trucada
        call = params[:call] # Valor de chamada de truco (3, 6, 9, 12)
    
        # Encontre o jogador e verifique se está na partida pelo nome
        player_chair = find_player_chair(@game.room, player_name)
        unless player_chair
          render json: { error: "Player is not part of this game" }, status: :forbidden
          return
        end
    
        # Verifique se é a vez do jogador
        step = @game.steps.order(:number).last
        if step.player_time != player_name
          render json: { error: "Not your turn" }, status: :forbidden
          return
        end
    
        # Verifique se a carta é válida e está nas cartas do jogador
        if card && !step.send("cards_#{player_chair}").include?(card)
          render json: { error: "Invalid card or card not in player's hand" }, status: :unprocessable_entity
          return
        end
    
        # Log da jogada
        Rails.logger.info "Player #{player_name} plays card: #{card}, coverup: #{coverup}, accept: #{accept}, call: #{call}"
    
        # Validação adicional para o campo `call` (se é uma chamada válida de truco)
        if call && ![3, 6, 9, 12].include?(call)
          render json: { error: "Invalid truco call" }, status: :unprocessable_entity
          return
        end
    
        # Processamento da jogada (pode incluir lógica para atualizar o estado do jogo, registrar o movimento no `step`, etc.)
        render json: { message: "Move processed successfully" }, status: :ok
      end
    
      private
    
      # Encontra a cadeira do jogador pelo nome na sala associada ao jogo
      def find_player_chair(room, player_name)
        room.attributes.slice('chair_a', 'chair_b', 'chair_c', 'chair_d').find { |_, name| name == player_name }&.first
      end
    
      def set_game
        @game = Game.find_by(uuid: params[:uuid])
        render json: { error: 'Game not found' }, status: :not_found unless @game
      end
    end