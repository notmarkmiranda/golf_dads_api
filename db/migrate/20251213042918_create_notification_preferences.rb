class CreateNotificationPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_preferences do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.boolean :reservations_enabled, null: false, default: true
      t.boolean :group_activity_enabled, null: false, default: true
      t.boolean :reminders_enabled, null: false, default: true
      t.boolean :reminder_24h_enabled, null: false, default: true
      t.boolean :reminder_2h_enabled, null: false, default: true

      t.timestamps
    end
  end
end
