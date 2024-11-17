class AddIsAcceptFirstAndIsAcceptSecondToSteps < ActiveRecord::Migration[7.2]
  def change
    add_column :steps, :is_accept_first, :string
    add_column :steps, :is_accept_second, :string
  end
end
