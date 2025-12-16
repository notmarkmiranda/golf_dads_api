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

    # Send notification via FCM v1 API
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
          response = fcm_client.send_v1(
            message: build_message(token: token, title: title, body: body, data: data)
          )

          if response[:status_code] == 200
            success = true
          else
            # Token invalid or other error
            invalid_tokens << token if token_invalid?(response)
          end
        rescue StandardError => e
          Rails.logger.error("FCM send error for token #{token}: #{e.message}")
          # Check if token-related error
          invalid_tokens << token if e.message.include?("InvalidRegistration") || e.message.include?("NotRegistered")
        end
      end

      {
        success: success,
        error: success ? nil : "Failed to send to any device",
        invalid_tokens: invalid_tokens
      }
    end

    # Build FCM v1 message payload
    def build_message(token:, title:, body:, data:)
      {
        token: token,
        notification: {
          title: title,
          body: body
        },
        data: stringify_data(data),
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1
            }
          }
        }
      }
    end

    # Convert data hash values to strings (FCM requirement)
    def stringify_data(data)
      data.transform_values(&:to_s)
    end

    # Check if FCM is properly configured
    def fcm_configured?
      FCM_CONFIG[:project_id].present? &&
        FCM_CONFIG[:credentials_path].present? &&
        File.exist?(Rails.root.join(FCM_CONFIG[:credentials_path]))
    end

    # Get FCM client instance
    def fcm_client
      # Use absolute path if provided, otherwise join with Rails.root
      credentials_path = if FCM_CONFIG[:credentials_path].start_with?('/')
                          FCM_CONFIG[:credentials_path]
                        else
                          Rails.root.join(FCM_CONFIG[:credentials_path]).to_s
                        end

      @fcm_client ||= FCM.new(
        credentials_path,
        FCM_CONFIG[:project_id]
      )
    end

    # Check if response indicates invalid token
    def token_invalid?(response)
      response[:status_code] == 404 ||
        response[:body]&.include?("InvalidRegistration") ||
        response[:body]&.include?("NotRegistered")
    end

    # Remove invalid tokens from database
    def cleanup_invalid_tokens(user, invalid_tokens)
      return if invalid_tokens.empty?

      user.device_tokens.where(token: invalid_tokens).destroy_all
      Rails.logger.info("Removed #{invalid_tokens.count} invalid tokens for user #{user.id}")
    end
  end
end
