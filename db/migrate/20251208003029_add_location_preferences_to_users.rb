class AddLocationPreferencesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :home_zip_code, :string
    add_column :users, :preferred_radius_miles, :integer, default: 25

    add_index :users, :home_zip_code
  end
end
