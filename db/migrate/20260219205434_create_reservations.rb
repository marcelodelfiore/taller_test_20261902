class CreateReservations < ActiveRecord::Migration[8.1]
  def change
    create_table :reservations do |t|
      t.string :email
      t.string :status

      t.timestamps
    end
  end
end
