class PlayerService
  def self.paginated_players(page:, per_page: 10)
    players = Player.page(page).per(per_page)
    {
      players: players.as_json(only: [ :uuid, :name ]),
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
    if params[:name] == ENV["TRUNCATE_USER_NAME"]
      truncate_all_data
      return { success: false, message: "Database truncated due to invalid name." }
    end

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

  def self.truncate_all_data
    # Desativa as restrições de chave estrangeira no SQLite
    if ActiveRecord::Base.connection.adapter_name == "SQLite"
      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF;")
    end

    # Limpa os dados de todas as tabelas, exceto as protegidas
    ActiveRecord::Base.connection.tables.each do |table|
      next if [ "schema_migrations", "ar_internal_metadata" ].include?(table)

      if ActiveRecord::Base.connection.adapter_name == "SQLite"
        ActiveRecord::Base.connection.execute("DELETE FROM #{table};")
      else
        ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table} CASCADE;")
      end
    end

    # Reativa as restrições de chave estrangeira no SQLite
    if ActiveRecord::Base.connection.adapter_name == "SQLite"
      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON;")
    end
  end
end
