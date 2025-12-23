# Service for sending push notifications via Firebase Cloud Messaging (FCM)
#
# Usage:
#   PushNotificationService.send_to_user(
#     user,
#     title: "New Reservation",
#     body: "John reserved a spot",
#     data: { tee_time_id: 123 },
#     notification_type: :reservation_created
#   )
#
class PushNotificationService
  class << self
    # Send notification to a single user
    #
    # @param user [User] The user to send notification to
    # @param title [String] Notification title
    # @param body [String] Notification body
    # @param data [Hash] Additional data payload
    # @param notification_type [Symbol] Type of notification (e.g., :reservation_created)
    # @return [Boolean] true if sent successfully, false otherwise
    def send_to_user(user, title:, body:, data: {}, notification_type:)
      # Check if user has notification preferences enabled for this type
      return false unless should_send_notification?(user, notification_type)

      # Get active device tokens for user
      tokens = user.device_tokens.active.pluck(:token)
      return false if tokens.empty?

      # Create notification log
      log = create_notification_log(
        user: user,
        title: title,
        body: body,
        data: data,
        notification_type: notification_type
      )

      begin
        # Send via FCM
        response = send_fcm_notification(
          tokens: tokens,
          title: title,
          body: body,
          data: data
        )

        # Handle response
        if response[:success]
          log.mark_as_sent!
          cleanup_invalid_tokens(user, response[:invalid_tokens]) if response[:invalid_tokens].any?
          true
        else
          log.mark_as_failed!(response[:error])
          false
        end
      rescue StandardError => e
        log.mark_as_failed!(e)
        Rails.logger.error("Push notification error for user #{user.id}: #{e.message}")
        false
      end
    end

    # Send notification to multiple users
    #
    # @param users [Array<User>] Users to send notification to
    # @param title [String] Notification title
    # @param body [String] Notification body
    # @param data [Hash] Additional data payload
    # @param notification_type [Symbol] Type of notification
    # @return [Hash] { success_count: Integer, failure_count: Integer }
    def send_to_users(users, title:, body:, data: {}, notification_type:)
      results = { success_count: 0, failure_count: 0 }

      users.each do |user|
        if send_to_user(user, title: title, body: body, data: data, notification_type: notification_type)
          results[:success_count] += 1
        else
          results[:failure_count] += 1
        end
      end

      results
    end

    # Format tee time for a specific device's timezone
    #
    # @param tee_time [ActiveSupport::TimeWithZone] The tee time in UTC
    # @param device_token [DeviceToken] The device token (may have timezone)
    # @return [String] Formatted string like "Dec 25 at 10:15am" or "Dec 25 at 5:15pm UTC"
    def format_tee_time_for_device(tee_time, device_token)
      tz = device_token.time_zone

      if tz
        # Device has timezone - format in local time, no timezone shown
        local_time = tee_time.in_time_zone(tz)
        date = local_time.strftime("%b %-d")
        time = local_time.strftime("%-I:%M%p").downcase
        "#{date} at #{time}"
      else
        # Fallback for devices without timezone - show UTC suffix
        date = tee_time.strftime("%b %-d")
        time = tee_time.strftime("%-I:%M%p").downcase
        "#{date} at #{time} UTC"
      end
    end

    private

    # Check if notification should be sent based on user preferences
    def should_send_notification?(user, notification_type)
      preference = user.notification_preference
      return false unless preference

      preference.enabled_for?(notification_type)
    end

    # Create notification log entry
    def create_notification_log(user:, title:, body:, data:, notification_type:)
      NotificationLog.create!(
        user: user,
        notification_type: notification_type.to_s,
        title: title,
        body: body,
        data: data,
        status: "pending"
      )
    end

    # Send notification via FCM v1 API using Google's official gem
    def send_fcm_notification(tokens:, title:, body:, data:)
      # Check if FCM is configured
      unless fcm_configured?
        return {
          success: false,
          error: "FCM not configured",
          invalid_tokens: []
        }
      end

      invalid_tokens = []
      success = false

      # Send to each token (FCM v1 doesn't support multicast like legacy API)
      tokens.each do |token|
        begin
          message = build_message(token: token, title: title, body: body, data: data)

          response = fcm_service.send_message(
            "projects/#{FCM_CONFIG[:project_id]}",
            Google::Apis::FcmV1::SendMessageRequest.new(message: message)
          )

          # If we got a response with a name, it succeeded
          if response.name.present?
            success = true
            Rails.logger.info("FCM notification sent successfully: #{response.name}")
          end
        rescue Google::Apis::ClientError => e
          Rails.logger.error("FCM send error for token #{token}: #{e.message}")

          # Check if token-related error (404 = not found, 400 = invalid)
          if e.status_code == 404 || e.message.include?("not a valid FCM registration token")
            invalid_tokens << token
          end
        rescue StandardError => e
          Rails.logger.error("Unexpected FCM error for token #{token}: #{e.message}")
        end
      end

      {
        success: success,
        error: success ? nil : "Failed to send to any device",
        invalid_tokens: invalid_tokens
      }
    end

    # Build FCM v1 message payload using Google's API objects
    def build_message(token:, title:, body:, data:)
      Google::Apis::FcmV1::Message.new(
        token: token,
        notification: Google::Apis::FcmV1::Notification.new(
          title: title,
          body: body
        ),
        data: stringify_data(data),
        apns: Google::Apis::FcmV1::ApnsConfig.new(
          payload: {
            "aps" => {
              "sound" => "default",
              "badge" => 1
            }
          }
        )
      )
    end

    # Convert data hash values to strings (FCM requirement)
    def stringify_data(data)
      data.transform_values(&:to_s)
    end

    # Check if FCM is properly configured
    def fcm_configured?
      FCM_CONFIG[:project_id].present? &&
        FCM_CONFIG[:credentials_path].present? &&
        File.exist?(credentials_file_path)
    end

    # Get the full path to credentials file
    def credentials_file_path
      if FCM_CONFIG[:credentials_path].start_with?("/")
        FCM_CONFIG[:credentials_path]
      else
        Rails.root.join(FCM_CONFIG[:credentials_path]).to_s
      end
    end

    # Get FCM service instance with OAuth2 authentication
    def fcm_service
      return @fcm_service if @fcm_service

      require "google/apis/fcm_v1"
      require "googleauth"

      @fcm_service = Google::Apis::FcmV1::FirebaseCloudMessagingService.new

      # Authenticate using service account
      scopes = [ "https://www.googleapis.com/auth/firebase.messaging" ]
      @fcm_service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(credentials_file_path),
        scope: scopes
      )

      @fcm_service
    end

    # Remove invalid tokens from database
    def cleanup_invalid_tokens(user, invalid_tokens)
      return if invalid_tokens.empty?

      user.device_tokens.where(token: invalid_tokens).destroy_all
      Rails.logger.info("Removed #{invalid_tokens.count} invalid tokens for user #{user.id}")
    end
  end
end
