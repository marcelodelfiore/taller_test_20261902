class AddBookRefToReservations < ActiveRecord::Migration[8.1]
  def change
    add_reference :reservations, :book, null: false, foreign_key: true
    add_index :reservations, [:book_id, :status]
  end
end
