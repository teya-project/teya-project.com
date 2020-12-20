class Website < ApplicationRecord
  validates :domain_name, presence: true, length: { minimum: 3 }
end
