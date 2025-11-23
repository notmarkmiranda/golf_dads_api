class AddOAuthFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :avatar_url, :string

    # Index for fast OAuth user lookups
    add_index :users, [:provider, :uid], unique: true
  end
end
