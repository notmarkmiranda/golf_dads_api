# Background job to send push notifications for upcoming tee times
# Runs hourly via Solid Queue recurring tasks
#
# Sends two types of reminders:
# - 24 hours before tee time
# - 2 hours before tee time
#
# Usage (typically called by Solid Queue recurring tasks):
#   TeeTimeReminderJob.perform_later
#
class TeeTimeReminderJob < ApplicationJob
  queue_as :default

  def perform
    send_24_hour_reminders
    send_2_hour_reminders
  end

  private

  # Send reminders for tee times 23-25 hours away
  def send_24_hour_reminders
    tee_times = TeeTimePosting
      .where(tee_time: 23.hours.from_now..25.hours.from_now)
      .includes(:user, :reservations)

    tee_times.each do |tee_time|
      send_reminder(tee_time, timeframe: "24h")
    end

    Rails.logger.info("Sent 24h reminders for #{tee_times.count} tee times")
  end

  # Send reminders for tee times 1.5-2.5 hours away
  def send_2_hour_reminders
    tee_times = TeeTimePosting
      .where(tee_time: 1.5.hours.from_now..2.5.hours.from_now)
      .includes(:user, :reservations)

    tee_times.each do |tee_time|
      send_reminder(tee_time, timeframe: "2h")
    end

    Rails.logger.info("Sent 2h reminders for #{tee_times.count} tee times")
  end

  # Send reminder notification to posting owner and all reservers
  def send_reminder(tee_time, timeframe:)
    # Collect all users to notify (owner + reservers)
    users_to_notify = [ tee_time.user ] + tee_time.reservations.map(&:user)
    users_to_notify.uniq!

    course_name = tee_time.golf_course&.name || "Unknown Course"
    notification_type = timeframe == "24h" ? :reminder_24h : :reminder_2h
    title = timeframe == "24h" ? "Tee Time Tomorrow" : "Tee Time in 2 Hours"

    # Send to each user's device tokens with timezone-specific formatting
    users_to_notify.each do |user|
      user.device_tokens.active.each do |device_token|
        # Format tee time in device's timezone
        formatted_time = PushNotificationService.format_tee_time_for_device(
          tee_time.tee_time,
          device_token
        )

        PushNotificationService.send_to_user(
          user,
          title: title,
          body: "#{course_name} on #{formatted_time}",
          data: {
            type: "reminder",
            tee_time_id: tee_time.id,
            timeframe: timeframe
          },
          notification_type: notification_type
        )
      end
    end
  end
end
