module Api
  module V1
    class NotificationPreferencesController < Api::BaseController
      before_action :require_authentication

      # GET /api/v1/notification_preferences
      def show
        preference = current_user.notification_preference || current_user.create_notification_preference
        render json: notification_preference_response(preference), status: :ok
      end

      # PATCH /api/v1/notification_preferences
      def update
        preference = current_user.notification_preference || current_user.create_notification_preference

        if preference.update(preference_params)
          render json: notification_preference_response(preference), status: :ok
        else
          validation_error_response(preference.errors.messages)
        end
      end

      private

      def preference_params
        params.require(:notification_preferences).permit(
          :reservations_enabled,
          :group_activity_enabled,
          :reminders_enabled,
          :reminder_24h_enabled,
          :reminder_2h_enabled
        )
      end

      def notification_preference_response(preference)
        {
          id: preference.id,
          user_id: preference.user_id,
          reservations_enabled: preference.reservations_enabled,
          group_activity_enabled: preference.group_activity_enabled,
          reminders_enabled: preference.reminders_enabled,
          reminder_24h_enabled: preference.reminder_24h_enabled,
          reminder_2h_enabled: preference.reminder_2h_enabled
        }
      end
    end
  end
end
