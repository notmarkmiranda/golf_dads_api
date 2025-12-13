class CreateNotificationLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_logs do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :notification_type, null: false, index: true
      t.string :status, null: false, default: 'pending', index: true
      t.string :title, null: false
      t.text :body, null: false
      t.json :data
      t.text :error_message
      t.datetime :sent_at, index: true

      t.timestamps
    end
  end
end
