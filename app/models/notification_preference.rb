# frozen_string_literal: true

class NotificationPreference < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true

  # Check if a specific notification type is enabled
  def enabled_for?(notification_type)
    case notification_type.to_sym
    when :reservation_created, :reservation_cancelled
      reservations_enabled
    when :group_tee_time
      group_activity_enabled
    when :reminder_24h
      reminders_enabled && reminder_24h_enabled
    when :reminder_2h
      reminders_enabled && reminder_2h_enabled
    else
      false
    end
  end
end
