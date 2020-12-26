class ChangeTypeOfCollumnDomainExpiresDate < ActiveRecord::Migration[6.1]
  def change
    change_column(:websites, :domain_expires_date, :string)
  end
end
