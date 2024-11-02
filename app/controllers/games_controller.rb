class GamesController < ApplicationController
  before_action :authenticate_player, only: [:show, :play_move]
  before_action :set_game, only: [:show, :play_move]

  def show
    player_name = request.headers['name']
    game = Game.find_by(uuid: params[:uuid])

    if game
      player_chair = find_player_chair(game.room, player_name)
      unless player_chair
        render json: { error: "Player is not part of this game" }, status: :forbidden
        return
      end

      step = game.steps.order(:number).last
      step_data = step.as_json
      %w[cards_chair_a cards_chair_b cards_chair_c cards_chair_d].each do |chair|
        step_data[chair] = (chair == "cards_#{player_chair}") ? step.send(chair) : []
      end

      render json: game.as_json_with_chairs.merge(
        step: step_data,
        room_name: game.room.name
      )
    else
      render json: { error: 'Game not found' }, status: :not_found
    end
  end

  def play_move
    player_name = request.headers['name']
    card = params[:card]
    coverup = ActiveModel::Type::Boolean.new.cast(params[:coverup])
    accept = ActiveModel::Type::Boolean.new.cast(params[:accept])
    call = params[:call]

    player_chair = find_player_chair(@game.room, player_name)
    unless player_chair
      render json: { error: "Player is not part of this game" }, status: :forbidden
      return
    end

    step = @game.steps.order(:number).last
    if step.player_time != player_name
      render json: { error: "Not your turn" }, status: :forbidden
      return
    end

    if card && !step.send("cards_#{player_chair}").include?(card)
      render json: { error: "Invalid card or card not in player's hand" }, status: :unprocessable_entity
      return
    end

    Rails.logger.info "Player #{player_name} plays card: #{card}, coverup: #{coverup}, accept: #{accept}, call: #{call}"

    if call && ![3, 6, 9, 12].include?(call)
      render json: { error: "Invalid truco call" }, status: :unprocessable_entity
      return
    end

    # Move card to table_cards and removes it from player's hand
    step.table_cards << card
    step.update(table_cards: step.table_cards)
    player_cards = step.send("cards_#{player_chair}")
    player_cards.delete(card)
    step.update("cards_#{player_chair}" => player_cards)

    # Determine next player in sequence A -> D -> B -> C -> A
    chair_order = %w[A D B C]
    next_chair = chair_order[(chair_order.index(player_chair[-1].upcase) + 1) % chair_order.length]
    next_player_name = @game.room.send("chair_#{next_chair.downcase}")
    step.update(player_time: next_player_name)

    head :ok
  end

  private

  def find_player_chair(room, player_name)
    room.attributes.slice('chair_a', 'chair_b', 'chair_c', 'chair_d').find { |_, name| name == player_name }&.first
  end

  def set_game
    @game = Game.find_by(uuid: params[:uuid])
    render json: { error: 'Game not found' }, status: :not_found unless @game
  end
end
