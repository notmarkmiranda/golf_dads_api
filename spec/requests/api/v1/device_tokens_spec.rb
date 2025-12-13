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
