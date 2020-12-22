class AddRknStatus2 < ActiveRecord::Migration[6.1]
  def change
    add_column :websites, :rkn_status, :boolean
  end
end
