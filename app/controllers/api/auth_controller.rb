module Api
  class AuthController < Api::BaseController
    # POST /api/auth/signup
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
        }, status: :unprocessable_entity
      end
    end

    # POST /api/auth/login
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
