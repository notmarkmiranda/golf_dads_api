require 'rails_helper'

RSpec.describe 'Api::V1::NotificationPreferences', type: :request do
  let(:user) { create(:user) }
  let(:token) { user.generate_jwt }
  let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /api/v1/notification_preferences' do
    context 'with valid authentication' do
      it 'returns user notification preferences' do
        get '/api/v1/notification_preferences', headers: auth_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['user_id']).to eq(user.id)
        expect(json['reservations_enabled']).to eq(true)
        expect(json['group_activity_enabled']).to eq(true)
        expect(json['reminders_enabled']).to eq(true)
        expect(json['reminder_24h_enabled']).to eq(true)
        expect(json['reminder_2h_enabled']).to eq(true)
      end

      it 'creates preferences if they do not exist' do
        user.notification_preference&.destroy

        expect {
          get '/api/v1/notification_preferences', headers: auth_headers
        }.to change(NotificationPreference, :count).by(1)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'without authentication' do
      it 'returns unauthorized error' do
        get '/api/v1/notification_preferences'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/notification_preferences' do
    let!(:preference) { user.notification_preference }

    context 'with valid authentication' do
      it 'updates notification preferences' do
        patch '/api/v1/notification_preferences',
          params: {
            notification_preferences: {
              reservations_enabled: false,
              group_activity_enabled: false,
              reminders_enabled: true,
              reminder_24h_enabled: false,
              reminder_2h_enabled: true
            }
          },
          headers: auth_headers,
          as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['reservations_enabled']).to eq(false)
        expect(json['group_activity_enabled']).to eq(false)
        expect(json['reminders_enabled']).to eq(true)
        expect(json['reminder_24h_enabled']).to eq(false)
        expect(json['reminder_2h_enabled']).to eq(true)

        preference.reload
        expect(preference.reservations_enabled).to eq(false)
        expect(preference.group_activity_enabled).to eq(false)
      end

      it 'creates preferences if they do not exist' do
        user.notification_preference&.destroy

        expect {
          patch '/api/v1/notification_preferences',
            params: { notification_preferences: { reservations_enabled: false } },
            headers: auth_headers,
            as: :json
        }.to change(NotificationPreference, :count).by(1)

        expect(response).to have_http_status(:ok)
      end

      it 'allows partial updates' do
        patch '/api/v1/notification_preferences',
          params: { notification_preferences: { reservations_enabled: false } },
          headers: auth_headers,
          as: :json

        expect(response).to have_http_status(:ok)
        preference.reload
        expect(preference.reservations_enabled).to eq(false)
        expect(preference.group_activity_enabled).to eq(true) # unchanged
      end

      it 'accepts correct format for numbered reminder fields' do
        # Verify backend accepts reminder_24h_enabled (correct format)
        patch '/api/v1/notification_preferences',
          params: {
            notification_preferences: {
              reminder_24h_enabled: false,
              reminder_2h_enabled: false
            }
          },
          headers: auth_headers,
          as: :json

        expect(response).to have_http_status(:ok)
        preference.reload
        expect(preference.reminder_24h_enabled).to eq(false)
        expect(preference.reminder_2h_enabled).to eq(false)
      end

      it 'rejects incorrect format for numbered reminder fields' do
        # Verify backend rejects reminder24_h_enabled (incorrect format)
        # This is what iOS was sending before the fix
        initial_24h_state = preference.reminder_24h_enabled

        patch '/api/v1/notification_preferences',
          params: {
            notification_preferences: {
              reminder24_h_enabled: false,  # Wrong format - should be reminder_24h_enabled
              reminder2_h_enabled: false    # Wrong format - should be reminder_2h_enabled
            }
          },
          headers: auth_headers,
          as: :json

        # Request should succeed (200) but unpermitted params are ignored
        expect(response).to have_http_status(:ok)

        # Verify the values were NOT changed (unpermitted params ignored)
        preference.reload
        expect(preference.reminder_24h_enabled).to eq(initial_24h_state)
      end
    end

    context 'without authentication' do
      it 'returns unauthorized error' do
        patch '/api/v1/notification_preferences',
          params: { notification_preferences: { reservations_enabled: false } },
          as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
