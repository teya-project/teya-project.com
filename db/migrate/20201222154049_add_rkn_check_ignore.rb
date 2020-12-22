class AddRknCheckIgnore < ActiveRecord::Migration[6.1]
  def change
    add_column :websites, :rkn_check_ignore, :boolean
  end
end
