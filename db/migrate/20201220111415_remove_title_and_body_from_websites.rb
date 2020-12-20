class RemoveTitleAndBodyFromWebsites < ActiveRecord::Migration[6.1]
  def change
    remove_column :websites, :title, :string
    remove_column :websites, :body, :string
  end
end
