class AddThirdToSteps < ActiveRecord::Migration[7.2]
  def change
    add_column :steps, :third, :string
  end
end