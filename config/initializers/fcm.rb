# frozen_string_literal: true

# Firebase Cloud Messaging (FCM) configuration
#
# FCM uses service account JSON for authentication via OAuth2.
# The service account file should be placed at the path specified in FCM_CREDENTIALS_PATH.
#
# Required environment variables:
# - FCM_PROJECT_ID: Your Firebase project ID
# - FCM_CREDENTIALS_PATH: Path to the Firebase service account JSON file
#
# Example .env:
# FCM_PROJECT_ID=three-putt
# FCM_CREDENTIALS_PATH=config/firebase-service-account.json

FCM_CONFIG = {
  project_id: ENV.fetch("FCM_PROJECT_ID", nil),
  credentials_path: ENV.fetch("FCM_CREDENTIALS_PATH", nil)
}.freeze

# Validate that FCM credentials are configured
unless FCM_CONFIG[:project_id].present?
  Rails.logger.warn "FCM_PROJECT_ID is not set. Push notifications will not be available."
end

unless FCM_CONFIG[:credentials_path].present?
  Rails.logger.warn "FCM_CREDENTIALS_PATH is not set. Push notifications will not be available."
end

if FCM_CONFIG[:credentials_path].present?
  credentials_file = Rails.root.join(FCM_CONFIG[:credentials_path])
  unless File.exist?(credentials_file)
    Rails.logger.warn "FCM credentials file not found at: #{credentials_file}. Push notifications will not be available."
  end
end
