class AddNotificationPreferencesToExistingUsers < ActiveRecord::Migration[8.1]
  def up
    # Create default notification preferences for existing users that don't have them
    User.find_each do |user|
      unless user.notification_preference
        NotificationPreference.create!(
          user: user,
          reservations_enabled: true,
          group_activity_enabled: true,
          reminders_enabled: true,
          reminder_24h_enabled: true,
          reminder_2h_enabled: true
        )
      end
    end
  end

  def down
    # No rollback needed - preferences can remain
  end
end
