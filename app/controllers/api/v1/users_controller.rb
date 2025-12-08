module Api
  module V1
    class UsersController < Api::BaseController
      before_action :require_authentication

      # GET /api/v1/users/me
      def me
        render json: user_response(current_user), status: :ok
      end

      # PATCH /api/v1/users/me
      def update
        if current_user.update(update_params)
          render json: user_response(current_user), status: :ok
        else
          validation_error_response(current_user.errors.messages)
        end
      end

      private

      def update_params
        params.require(:user).permit(:name, :venmo_handle, :handicap, :home_zip_code, :preferred_radius_miles)
      end

      def user_response(user)
        {
          id: user.id,
          email: user.email_address,
          name: user.name,
          avatar_url: user.avatar_url,
          provider: user.provider,
          venmo_handle: user.venmo_handle,
          handicap: user.handicap,
          home_zip_code: user.home_zip_code,
          preferred_radius_miles: user.preferred_radius_miles
        }
      end
    end
  end
end
