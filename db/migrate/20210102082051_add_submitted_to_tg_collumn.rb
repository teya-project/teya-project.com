class AddSubmittedToTgCollumn < ActiveRecord::Migration[6.1]
  def change
    add_column :websites, :submitted_to_tg, :boolean
  end
end
