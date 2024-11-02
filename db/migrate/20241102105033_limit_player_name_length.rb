class LimitPlayerNameLength < ActiveRecord::Migration[7.2]
  def change
    change_column :players, :name, :string, limit: 10

    # Verifica se o índice único já existe antes de tentar adicioná-lo
    unless index_exists?(:players, :name, unique: true)
      add_index :players, :name, unique: true
    end
  end
end