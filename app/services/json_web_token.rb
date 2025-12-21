class JsonWebToken
  SECRET_KEY = Rails.application.credentials.secret_key_base

  # Encode a payload into a JWT token
  # @param payload [Hash] The data to encode in the token
  # @param exp [Integer] Optional expiration time (defaults to JWT_EXPIRATION_DAYS env var, or 30 days)
  # @return [String] The encoded JWT token
  def self.encode(payload, exp: nil)
    payload[:exp] = exp || default_expiration_time
    JWT.encode(payload, SECRET_KEY, "HS256")
  end

  # Decode a JWT token
  # @param token [String] The JWT token to decode
  # @return [Hash, nil] The decoded payload or nil if invalid/expired
  def self.decode(token)
    return nil if token.blank?

    decoded = JWT.decode(token, SECRET_KEY, true, algorithm: "HS256")
    HashWithIndifferentAccess.new(decoded.first)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

  private

  def self.default_expiration_time
    days = ENV.fetch('JWT_EXPIRATION_DAYS', '30').to_i
    days = 30 if days <= 0 || days > 365  # Bounds validation
    days.days.from_now.to_i
  end
end
