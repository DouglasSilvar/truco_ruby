class AddHandle11AcceptToSteps < ActiveRecord::Migration[7.2]
  def change
    add_column :steps, :handle_11_accept_first, :string
    add_column :steps, :handle_11_accept_second, :string
  end
end