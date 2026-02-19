class AddStatusToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :status, :string, null: false, default: 'available'
    add_index :books, :status
  end
end
