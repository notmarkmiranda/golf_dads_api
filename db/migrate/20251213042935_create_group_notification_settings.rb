class CreateGroupNotificationSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :group_notification_settings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.boolean :muted, null: false, default: false

      t.timestamps
    end

    add_index :group_notification_settings, [ :user_id, :group_id ], unique: true
  end
end
