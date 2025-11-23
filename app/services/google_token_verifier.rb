class GoogleTokenVerifier
  # Verify a Google ID token and return the payload
  # @param token [String] The Google ID token to verify
  # @return [Hash, nil] The token payload or nil if invalid
  def self.verify(token)
    return nil if token.blank?

    client_id = ENV['GOOGLE_CLIENT_ID'] || 'test_client_id'
    validator = GoogleIDToken::Validator.new
    payload = validator.check(token, client_id)

    # Ensure email is verified
    return nil unless payload && payload['email_verified']

    payload
  rescue StandardError => e
    Rails.logger.error("Google token verification failed: #{e.message}")
    nil
  end

  # Extract user information from Google payload
  # @param payload [Hash] The verified Google token payload
  # @return [Hash] User information hash
  def self.extract_user_info(payload)
    {
      uid: payload['sub'],
      email: payload['email'],
      name: payload['name'],
      avatar_url: payload['picture'],
      provider: 'google'
    }
  end
end
