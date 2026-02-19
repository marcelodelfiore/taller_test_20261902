class Reservation < ApplicationRecord
  belongs_to :book

  STATUSES = %w[reserved canceled fulfilled].freeze

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, presence: true, inclusion: { in: STATUSES }
end
