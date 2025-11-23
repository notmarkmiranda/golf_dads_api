class JsonWebToken
  SECRET_KEY = Rails.application.credentials.secret_key_base

  # Encode a payload into a JWT token
  # @param payload [Hash] The data to encode in the token
  # @param exp [Integer] Optional expiration time (defaults to 24 hours from now)
  # @return [String] The encoded JWT token
  def self.encode(payload, exp: nil)
    payload[:exp] = exp || 24.hours.from_now.to_i
    JWT.encode(payload, SECRET_KEY, 'HS256')
  end

  # Decode a JWT token
  # @param token [String] The JWT token to decode
  # @return [Hash, nil] The decoded payload or nil if invalid/expired
  def self.decode(token)
    return nil if token.blank?

    decoded = JWT.decode(token, SECRET_KEY, true, algorithm: 'HS256')
    HashWithIndifferentAccess.new(decoded.first)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
