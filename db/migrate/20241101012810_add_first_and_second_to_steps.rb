class AddFirstAndSecondToSteps < ActiveRecord::Migration[7.2]
  def change
    add_column :steps, :first, :string
    add_column :steps, :second, :string
  end
end
