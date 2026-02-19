class Book < ApplicationRecord
  has_many :reservations, dependent: :destroy

  STATUSES = %w[available reserved checked_out].freeze

  validates :author, :title, presence: true
  validates :status, inclusion: { in: STATUSES }

  def reserved?
    status == 'reserved'
  end

  def checked_out?
    status == 'checked_out'
  end
end
