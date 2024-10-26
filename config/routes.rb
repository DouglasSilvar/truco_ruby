Rails.application.routes.draw do
  resources :players, only: [:index,:create]
  
  resources :rooms, only: [:index, :create, :show]
  post 'rooms/:uuid/join', to: 'rooms#join_room'
  post 'rooms/:uuid/leave', to: 'rooms#leave_room'
  post 'rooms/:uuid/changechair', to: 'rooms#change_chair'
end
