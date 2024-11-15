class AddEndGameWinToGames < ActiveRecord::Migration[7.0]
  def change
    add_column :games, :end_game_win, :string, default: nil
  end
end
