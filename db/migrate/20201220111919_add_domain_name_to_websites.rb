class AddDomainNameToWebsites < ActiveRecord::Migration[6.1]
  def change
    add_column :websites, :domain_name, :string
  end
end
