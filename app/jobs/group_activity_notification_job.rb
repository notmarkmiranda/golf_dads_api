# Background job to send push notifications when new tee times are posted in groups
#
# Usage:
#   GroupActivityNotificationJob.perform_later(tee_time_id)
#
class GroupActivityNotificationJob < ApplicationJob
  queue_as :default

  # @param tee_time_id [Integer] ID of the tee time posting
  def perform(tee_time_id)
    tee_time = TeeTimePosting.find_by(id: tee_time_id)
    return unless tee_time
    return unless tee_time.groups.any?

    poster = tee_time.user
    poster_name = poster.name || poster.email_address.split("@").first
    course_name = tee_time.golf_course&.name || "Unknown Course"

    # Notify all group members (except poster and muted users)
    tee_time.groups.each do |group|
      notify_group_members(
        group: group,
        tee_time: tee_time,
        poster: poster,
        poster_name: poster_name,
        course_name: course_name
      )
    end
  end

  private

  def notify_group_members(group:, tee_time:, poster:, poster_name:, course_name:)
    # Get all group members except the poster
    members = group.members.where.not(id: poster.id)

    # Filter out users who have muted this group
    muted_user_ids = GroupNotificationSetting.muted
      .where(group_id: group.id, user_id: members.pluck(:id))
      .pluck(:user_id)

    members_to_notify = members.where.not(id: muted_user_ids)

    # Send notification to each member's device tokens with timezone-specific formatting
    members_to_notify.each do |member|
      member.device_tokens.active.each do |device_token|
        # Format tee time in device's timezone
        formatted_time = PushNotificationService.format_tee_time_for_device(
          tee_time.tee_time,
          device_token
        )

        PushNotificationService.send_to_user(
          member,
          title: group.name,
          body: "#{poster_name} posted a tee time at #{course_name} on #{formatted_time}",
          data: {
            type: "group_tee_time",
            tee_time_id: tee_time.id,
            group_id: group.id
          },
          notification_type: :group_tee_time
        )
      end
    end
  end
end
