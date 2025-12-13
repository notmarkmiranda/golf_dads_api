module Api
  module V1
    class AuthController < Api::BaseController
      skip_before_action :authenticate_request, only: [ :signup, :login, :google ]

    # POST /api/v1/auth/signup
    def signup
      user = User.new(signup_params)

      if user.save
        token = user.generate_jwt
        render json: {
          token: token,
          user: user_response(user)
        }, status: :created
      else
        validation_error_response(user.errors.messages)
      end
    end

    # POST /api/v1/auth/login
    def login
      user = User.find_by(email_address: params[:email]&.strip&.downcase)

      if user&.authenticate(params[:password])
        token = user.generate_jwt
        render json: {
          token: token,
          user: user_response(user)
        }, status: :ok
      else
        error_response(
          message: "Invalid email or password",
          status: :unauthorized
        )
      end
    end

    # POST /api/v1/auth/google
    def google
      id_token = params[:idToken] || params[:id_token]

      if id_token.blank?
        return error_response(
          message: "ID token is required",
          status: :bad_request
        )
      end

      begin
        # Verify token with Google
        payload = GoogleAuthService.verify_token(id_token)

        # Extract user info
        user_info = GoogleAuthService.extract_user_info(payload)

        # Verify email is confirmed by Google
        unless user_info[:email_verified]
          return error_response(
            message: "Email not verified by Google",
            status: :unauthorized
          )
        end

        # Find or create user
        user = User.from_google_auth(user_info)

        # Generate JWT token
        token = user.generate_jwt

        # Return response
        render json: {
          token: token,
          user: user_response(user)
        }, status: :ok

      rescue Google::Auth::IDTokens::VerificationError => e
        Rails.logger.error "Google Sign-In failed: #{e.message}"
        error_response(
          message: "Invalid Google ID token",
          status: :unauthorized
        )

      rescue StandardError => e
        Rails.logger.error "Google Sign-In error: #{e.class} - #{e.message}"
        error_response(
          message: "Authentication failed",
          status: :internal_server_error
        )
      end
    end

    private

    def signup_params
      params.require(:user).permit(:email, :password, :password_confirmation, :name).tap do |p|
        # Map 'email' param to 'email_address' for User model
        p[:email_address] = p.delete(:email) if p[:email]
      end
    end

    def user_response(user)
      {
        id: user.id,
        email: user.email_address,
        name: user.name,
        avatar_url: user.avatar_url,
        provider: user.provider,
        venmo_handle: user.venmo_handle,
        handicap: user.handicap
      }
    end
    end
  end
end
