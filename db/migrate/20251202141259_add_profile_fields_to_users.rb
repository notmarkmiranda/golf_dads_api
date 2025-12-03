class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :venmo_handle, :string
    add_column :users, :handicap, :decimal, precision: 4, scale: 1
  end
end
