class UpdateStepsForPlayerCards < ActiveRecord::Migration[7.2]
  def change
    # Remover a coluna antiga de cartas
    remove_column :steps, :cards, :json

    # Adicionar novas colunas para armazenar as cartas de cada cadeira
    add_column :steps, :cards_chair_a, :json, default: []
    add_column :steps, :cards_chair_b, :json, default: []
    add_column :steps, :cards_chair_c, :json, default: []
    add_column :steps, :cards_chair_d, :json, default: []

    # Garantindo que a coluna 'mania' ainda esteja na tabela
    add_column :steps, :mania, :string unless column_exists?(:steps, :mania)
  end
end
