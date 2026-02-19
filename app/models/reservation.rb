class Reservation < ApplicationRecord
  belongs_to :book

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
