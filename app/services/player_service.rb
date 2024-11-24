class PlayerService
  def self.paginated_players(page:, per_page: 10)
    players = Player.page(page).per(per_page)
    {
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

  def self.create_player(params)
    player = Player.new(params)
    if player.save
      { success: true, player: player }
    else
      { success: false, errors: player.errors.full_messages }
    end
  end

  def self.validate_player(name:, uuid:)
    Player.find_by(name: name, uuid: uuid).present?
  end
end
