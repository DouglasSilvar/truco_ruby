class RenameManiaToViraInSteps < ActiveRecord::Migration[7.2]
  def change
    rename_column :steps, :mania, :vira
  end
end
