module Api
  module V1
    class AuthController < Api::BaseController
      skip_before_action :authenticate_request, only: [:signup, :login, :google]

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
        render json: {
          errors: user.errors.messages
        }, status: :unprocessable_content
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
        render json: {
          error: 'Invalid email or password'
        }, status: :unauthorized
      end
    end

      # POST /api/v1/auth/google
    def google
      google_token = params[:token]
      payload = GoogleTokenVerifier.verify(google_token)

      unless payload
        return render json: {
          error: 'Invalid Google token'
        }, status: :unauthorized
      end

      user_info = GoogleTokenVerifier.extract_user_info(payload)
      user = User.from_oauth(**user_info)

      token = user.generate_jwt
      render json: {
        token: token,
        user: user_response(user)
      }, status: :ok
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
        provider: user.provider
      }
      end
    end
  end
end
