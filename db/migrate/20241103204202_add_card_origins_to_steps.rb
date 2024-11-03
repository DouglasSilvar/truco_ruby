class AddCardOriginsToSteps < ActiveRecord::Migration[7.2]
  def change
    add_column :steps, :first_card_origin, :string
    add_column :steps, :second_card_origin, :string
    add_column :steps, :third_card_origin, :string
    add_column :steps, :fourth_card_origin, :string
  end
end
