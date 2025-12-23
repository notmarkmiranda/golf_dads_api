class AddTimezoneToDeviceTokens < ActiveRecord::Migration[8.1]
  def change
    add_column :device_tokens, :timezone, :string
    add_index :device_tokens, :timezone
  end
end
