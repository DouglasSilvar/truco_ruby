class RoomPlayer < ApplicationRecord
  belongs_to :room, foreign_key: 'room_id', primary_key: 'uuid'
  belongs_to :player, foreign_key: 'player_id', primary_key: 'uuid'
end
