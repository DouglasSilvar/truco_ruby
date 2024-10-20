Rails.application.routes.draw do
  resources :players, only: [:index,:create]
  
  resources :rooms, only: [:index, :create]
  post 'rooms/:uuid/join', to: 'rooms#join_room'
  post 'rooms/:uuid/leave', to: 'rooms#leave_room'
end
