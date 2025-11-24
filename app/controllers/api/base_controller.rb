module Api
  class BaseController < ActionController::API
    include Pundit::Authorization

    # Pundit authorization error handling
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    # Authentication helper methods
    before_action :authenticate_request

    attr_reader :current_user

    private

    def authenticate_request
      header = request.headers['Authorization']
      token = header.split(' ').last if header

      begin
        decoded = JsonWebToken.decode(token)
        @current_user = User.find(decoded['user_id']) if decoded
      rescue ActiveRecord::RecordNotFound
        @current_user = nil
      end
    end

    def require_authentication
      return true if current_user

      render json: { error: 'Unauthorized' }, status: :unauthorized
      false
    end

    def user_not_authorized(exception)
      # If user is not authenticated, return 401 instead of 403
      if current_user.nil?
        render json: { error: 'Unauthorized' }, status: :unauthorized
      else
        render json: { error: 'You are not authorized to perform this action' }, status: :forbidden
      end
    end
  end
end
