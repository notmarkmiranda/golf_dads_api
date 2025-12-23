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
