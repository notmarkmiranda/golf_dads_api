module Api
  module V1
    class DeviceTokensController < Api::BaseController
      before_action :require_authentication

      # POST /api/v1/device_tokens
      def create
        device_token = current_user.device_tokens.find_or_initialize_by(token: token_params[:token])
        device_token.platform = token_params[:platform]
        device_token.timezone = token_params[:timezone] if token_params[:timezone].present?
        device_token.last_used_at = Time.current

        if device_token.save
          # Clean up old tokens for this user/platform to prevent duplicate notifications
          # Keep only the most recent token per platform
          cleanup_old_tokens(device_token)

          render json: device_token_response(device_token), status: :created
        else
          validation_error_response(device_token.errors.messages)
        end
      end

      # DELETE /api/v1/device_tokens/:token
      def destroy
        device_token = current_user.device_tokens.find_by!(token: params[:token])
        device_token.destroy

        head :no_content
      end

      private

      def cleanup_old_tokens(current_token)
        # Delete other tokens for this user on the same platform
        # This prevents duplicate notifications when user reinstalls or switches devices
        current_user.device_tokens
          .where(platform: current_token.platform)
          .where.not(id: current_token.id)
          .destroy_all

        Rails.logger.info("Cleaned up old device tokens for user #{current_user.id}, platform #{current_token.platform}")
      end

      def token_params
        params.require(:device_token).permit(:token, :platform, :timezone)
      end

      def device_token_response(device_token)
        {
          id: device_token.id,
          token: device_token.token,
          platform: device_token.platform,
          timezone: device_token.timezone,
          last_used_at: device_token.last_used_at
        }
      end
    end
  end
end
