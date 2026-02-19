class Book < ApplicationRecord
  has_many :reservation

  STATUS = %i(:reserved :checkout)
end
