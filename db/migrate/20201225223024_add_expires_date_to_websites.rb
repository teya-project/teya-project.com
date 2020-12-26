class AddExpiresDateToWebsites < ActiveRecord::Migration[6.1]
  def change
    add_column :websites, :domain_expires_date, :datetime
  end
end
