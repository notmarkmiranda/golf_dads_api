require 'rails_helper'

RSpec.describe 'Api::V1::DeviceTokens', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:token) { user.generate_jwt }
  let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'POST /api/v1/device_tokens' do
    context 'with valid authentication' do
      let(:valid_params) do
        {
          device_token: {
            token: 'fcm_token_12345',
            platform: 'ios'
          }
        }
      end

      it 'creates a new device token' do
        expect {
          post '/api/v1/device_tokens',
            params: valid_params,
            headers: auth_headers,
            as: :json
        }.to change(DeviceToken, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['token']).to eq('fcm_token_12345')
        expect(json['platform']).to eq('ios')
        expect(json['last_used_at']).to be_present
      end

      it 'updates existing device token if token already exists' do
        existing_token = create(:device_token, user: user, token: 'fcm_token_12345', platform: 'ios')

        expect {
          post '/api/v1/device_tokens',
            params: { device_token: { token: 'fcm_token_12345', platform: 'android' } },
            headers: auth_headers,
            as: :json
        }.not_to change(DeviceToken, :count)

        expect(response).to have_http_status(:created)
        existing_token.reload
        expect(existing_token.platform).to eq('android')
      end

      it 'updates last_used_at timestamp' do
        travel_to Time.zone.local(2024, 12, 1, 12, 0, 0) do
          post '/api/v1/device_tokens',
            params: valid_params,
            headers: auth_headers,
            as: :json

          json = JSON.parse(response.body)
          expect(Time.parse(json['last_used_at'])).to be_within(1.second).of(Time.current)
        end
      end

      it 'removes old tokens for same platform when registering new token' do
        # Create old tokens for this user on iOS
        old_token1 = create(:device_token, user: user, token: 'old_ios_token_1', platform: 'ios')
        old_token2 = create(:device_token, user: user, token: 'old_ios_token_2', platform: 'ios')
        # Create token on different platform (should not be deleted)
        android_token = create(:device_token, user: user, token: 'android_token', platform: 'android')

        # Register new token for iOS
        post '/api/v1/device_tokens',
          params: { device_token: { token: 'new_ios_token', platform: 'ios' } },
          headers: auth_headers,
          as: :json

        expect(response).to have_http_status(:created)

        # Verify old iOS tokens were deleted
        expect(DeviceToken.exists?(old_token1.id)).to be false
        expect(DeviceToken.exists?(old_token2.id)).to be false

        # Verify Android token was NOT deleted
        expect(DeviceToken.exists?(android_token.id)).to be true

        # Verify new token exists and is the only iOS token
        expect(DeviceToken.find_by(token: 'new_ios_token')).to be_present
        expect(user.device_tokens.where(platform: 'ios').count).to eq(1)
        expect(user.device_tokens.count).to eq(2) # 1 iOS + 1 Android
      end

      context 'with timezone parameter' do
        it 'creates device token with timezone' do
          params = {
            device_token: {
              token: 'fcm_token_with_tz',
              platform: 'ios',
              timezone: 'America/Denver'
            }
          }

          post '/api/v1/device_tokens',
            params: params,
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json['timezone']).to eq('America/Denver')

          device_token = DeviceToken.find_by(token: 'fcm_token_with_tz')
          expect(device_token.timezone).to eq('America/Denver')
        end

        it 'updates timezone for existing token' do
          existing_token = create(:device_token, user: user, token: 'fcm_token_12345', timezone: 'America/New_York')

          params = {
            device_token: {
              token: 'fcm_token_12345',
              platform: 'ios',
              timezone: 'America/Los_Angeles'
            }
          }

          post '/api/v1/device_tokens',
            params: params,
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:created)
          existing_token.reload
          expect(existing_token.timezone).to eq('America/Los_Angeles')
        end

        it 'accepts nil timezone (backward compatibility)' do
          params = {
            device_token: {
              token: 'fcm_token_no_tz',
              platform: 'ios'
            }
          }

          post '/api/v1/device_tokens',
            params: params,
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json['timezone']).to be_nil

          device_token = DeviceToken.find_by(token: 'fcm_token_no_tz')
          expect(device_token.timezone).to be_nil
        end

        it 'rejects invalid timezone' do
          params = {
            device_token: {
              token: 'fcm_token_invalid_tz',
              platform: 'ios',
              timezone: 'Invalid/Timezone'
            }
          }

          post '/api/v1/device_tokens',
            params: params,
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json['errors']['timezone']).to include('is not a valid timezone identifier')
        end
      end
    end

    context 'without authentication' do
      it 'returns unauthorized error' do
        post '/api/v1/device_tokens',
          params: { device_token: { token: 'test', platform: 'ios' } },
          as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with invalid params' do
      it 'returns validation errors for missing token' do
        post '/api/v1/device_tokens',
          params: { device_token: { platform: 'ios' } },
          headers: auth_headers,
          as: :json

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE /api/v1/device_tokens/:token' do
    let!(:device_token) { create(:device_token, user: user, token: 'fcm_token_12345') }

    context 'with valid authentication' do
      it 'deletes the device token' do
        expect {
          delete '/api/v1/device_tokens/fcm_token_12345', headers: auth_headers
        }.to change(DeviceToken, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it 'returns not found for non-existent token' do
        delete '/api/v1/device_tokens/nonexistent', headers: auth_headers

        expect(response).to have_http_status(:not_found)
      end

      it 'cannot delete another user\'s device token' do
        other_user = create(:user)
        other_token = create(:device_token, user: other_user, token: 'other_token')

        expect {
          delete '/api/v1/device_tokens/other_token', headers: auth_headers
        }.not_to change(DeviceToken, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'without authentication' do
      it 'returns unauthorized error' do
        delete '/api/v1/device_tokens/fcm_token_12345'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
