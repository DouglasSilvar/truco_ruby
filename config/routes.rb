Rails.application.routes.draw do
  resources :players, only: [:index,:create]
  get 'players/valid', to: 'players#validate_player'

  resources :rooms, only: [:index, :create, :show]
  post 'rooms/:uuid/join', to: 'rooms#join_room'
  post 'rooms/:uuid/leave', to: 'rooms#leave_room'
  post 'rooms/:uuid/changechair', to: 'rooms#change_chair'
  post 'rooms/:uuid/kick', to: 'rooms#kick_player'
  post 'rooms/:uuid/ready/:boolean', to: 'rooms#update_ready_status'
end
