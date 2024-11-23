class ApplicationController < ActionController::API
    before_action :authenticate_player, except: [ :create ]

    private

    def authenticate_player
      player_name = request.headers["name"]
      player_uuid = request.headers["uuid"]

      if player_name.blank? || player_uuid.blank?
        render json: { error: "Missing name or uuid in headers" }, status: :unauthorized
        return
      end

      player = Player.find_by(name: player_name, uuid: player_uuid)

      if player.nil?
        render json: { error: "Invalid player credentials" }, status: :unauthorized
      end
    end

    def authenticated_user?(name)
      Player.exists?(name: name)
    end
end
# rails db:truncate_all
# rails server -b 0.0.0.0
# rails db:migrate
# rails db:drop
# rails db:create
# rails db:reset
# rails generate migration
