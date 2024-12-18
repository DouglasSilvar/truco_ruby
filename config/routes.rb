Rails.application.routes.draw do
  resources :players, only: [ :index, :create ]
  get "players/valid", to: "players#validate_player"

  resources :rooms, only: [ :index, :create, :show ]
  post "rooms/:uuid/join", to: "rooms#join_room"
  post "rooms/:uuid/leave", to: "rooms#leave_room"
  post "rooms/:uuid/changechair", to: "rooms#change_chair"
  post "rooms/:uuid/kick", to: "rooms#kick_player"
  post "rooms/:uuid/ready/:boolean", to: "rooms#update_ready_status"
  post "rooms/:uuid/start", to: "rooms#start_game"
  post "rooms/:uuid/message", to: "rooms#send_message"
  post "rooms/:uuid/two_player/:boolean", to: "rooms#update_two_player_mode"

  resources :games, only: [ :show ], param: :uuid
  post "/games/:uuid/play_move", to: "games#play_move"
  post "/games/:uuid/call", to: "games#call"
  post "/games/:uuid/collect", to: "games#collect"
end
