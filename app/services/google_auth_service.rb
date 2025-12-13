# app/services/google_auth_service.rb
require "googleauth/id_tokens"

class GoogleAuthService
  class << self
    # Verify Google ID token and return payload
    # @param id_token [String] The Google ID token from iOS app
    # @return [Hash] The verified token payload
    # @raise [Google::Auth::IDTokens::VerificationError] If token is invalid
    def verify_token(id_token)
      client_id = google_client_id

      Rails.logger.info "🔍 Verifying Google token with client_id: #{client_id}"

      begin
        # Use Google's official googleauth gem to verify the token
        payload = Google::Auth::IDTokens.verify_oidc(id_token, aud: client_id)

        if payload
          Rails.logger.info "✅ Token verified successfully for user: #{payload['email']}"
          # Token is valid, return payload
          payload
        else
          Rails.logger.error "❌ Token validation returned nil"
          raise StandardError, "Invalid Google ID token"
        end
      rescue Google::Auth::IDTokens::VerificationError => e
        Rails.logger.error "❌ Google token verification failed: #{e.class} - #{e.message}"
        Rails.logger.error "   Backtrace: #{e.backtrace.first(5).join("\n   ")}"
        raise e
      rescue StandardError => e
        Rails.logger.error "❌ Unexpected error during token verification: #{e.class} - #{e.message}"
        raise e
      end
    end

    # Extract user info from verified token payload
    # @param payload [Hash] The verified token payload
    # @return [Hash] User information
    def extract_user_info(payload)
      {
        google_id: payload["sub"],           # Google user ID (unique identifier)
        email: payload["email"],              # User's email
        email_verified: payload["email_verified"],
        name: payload["name"],                # Full name
        given_name: payload["given_name"],    # First name
        family_name: payload["family_name"],  # Last name
        picture: payload["picture"]           # Profile picture URL
      }
    end

    private

    def google_client_id
      # Try environment variable first (development)
      return ENV["GOOGLE_CLIENT_ID"] if ENV["GOOGLE_CLIENT_ID"].present?

      # Fall back to credentials (production)
      Rails.application.credentials.dig(:google, :client_id)
    end
  end
end
