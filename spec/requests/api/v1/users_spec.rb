require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  let(:user) { create(:user, email_address: 'test@example.com', password: 'password123', name: 'Test User') }
  let(:token) { user.generate_jwt }
  let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /api/v1/users/me' do
    context 'with valid authentication' do
      it 'returns current user data' do
        get '/api/v1/users/me', headers: auth_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['id']).to eq(user.id)
        expect(json['email']).to eq('test@example.com')
        expect(json['name']).to eq('Test User')
      end

      it 'includes venmo_handle and handicap when set' do
        user.update(venmo_handle: '@testuser', handicap: 15.5)
        get '/api/v1/users/me', headers: auth_headers

        json = JSON.parse(response.body)
        expect(json['venmo_handle']).to eq('@testuser')
        expect(json['handicap']).to eq('15.5')
      end

      it 'includes location preferences when set' do
        user.update(home_zip_code: '94102', preferred_radius_miles: 50)
        get '/api/v1/users/me', headers: auth_headers

        json = JSON.parse(response.body)
        expect(json['home_zip_code']).to eq('94102')
        expect(json['preferred_radius_miles']).to eq(50)
      end

      it 'includes nil values for unset profile fields' do
        get '/api/v1/users/me', headers: auth_headers

        json = JSON.parse(response.body)
        expect(json['venmo_handle']).to be_nil
        expect(json['handicap']).to be_nil
        expect(json['home_zip_code']).to be_nil
      end

      it 'includes default value for preferred_radius_miles when not set' do
        get '/api/v1/users/me', headers: auth_headers

        json = JSON.parse(response.body)
        expect(json['preferred_radius_miles']).to eq(25)
      end
    end

    context 'without authentication' do
      it 'returns unauthorized error' do
        get '/api/v1/users/me'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized error' do
        get '/api/v1/users/me', headers: { 'Authorization' => 'Bearer invalid_token' }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/users/me' do
    context 'with valid authentication' do
      context 'updating venmo_handle' do
        it 'updates venmo_handle with @ prefix' do
          patch '/api/v1/users/me',
            params: { user: { venmo_handle: '@newhandle' } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['venmo_handle']).to eq('@newhandle')

          user.reload
          expect(user.venmo_handle).to eq('@newhandle')
        end

        it 'automatically adds @ prefix if missing' do
          patch '/api/v1/users/me',
            params: { user: { venmo_handle: 'newhandle' } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['venmo_handle']).to eq('@newhandle')

          user.reload
          expect(user.venmo_handle).to eq('@newhandle')
        end

        it 'allows clearing venmo_handle' do
          user.update(venmo_handle: '@oldhandle')

          patch '/api/v1/users/me',
            params: { user: { venmo_handle: '' } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['venmo_handle']).to be_nil

          user.reload
          expect(user.venmo_handle).to be_nil
        end
      end

      context 'updating location preferences' do
        it 'updates home_zip_code with valid 5-digit zip' do
          patch '/api/v1/users/me',
            params: { user: { home_zip_code: '94102' } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['home_zip_code']).to eq('94102')

          user.reload
          expect(user.home_zip_code).to eq('94102')
        end

        it 'updates preferred_radius_miles with valid value' do
          patch '/api/v1/users/me',
            params: { user: { preferred_radius_miles: 50 } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['preferred_radius_miles']).to eq(50)

          user.reload
          expect(user.preferred_radius_miles).to eq(50)
        end

        it 'allows clearing home_zip_code' do
          user.update(home_zip_code: '94102')

          patch '/api/v1/users/me',
            params: { user: { home_zip_code: nil } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['home_zip_code']).to be_nil

          user.reload
          expect(user.home_zip_code).to be_nil
        end

        it 'returns error for invalid zip code format' do
          patch '/api/v1/users/me',
            params: { user: { home_zip_code: '1234' } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json['errors']['home_zip_code']).to include('must be 5 digits')
        end

        it 'returns error for non-numeric zip code' do
          patch '/api/v1/users/me',
            params: { user: { home_zip_code: 'abcde' } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json['errors']['home_zip_code']).to include('must be 5 digits')
        end

        it 'returns error for radius less than or equal to 0' do
          patch '/api/v1/users/me',
            params: { user: { preferred_radius_miles: 0 } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json['errors']['preferred_radius_miles']).to include('must be greater than 0')
        end

        it 'returns error for radius over 100' do
          patch '/api/v1/users/me',
            params: { user: { preferred_radius_miles: 101 } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json['errors']['preferred_radius_miles']).to include('must be less than or equal to 100')
        end
      end

      context 'updating handicap' do
        it 'updates handicap with valid value' do
          patch '/api/v1/users/me',
            params: { user: { handicap: 27.5 } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['handicap']).to eq('27.5')

          user.reload
          expect(user.handicap).to eq(27.5)
        end

        it 'updates handicap with integer value' do
          patch '/api/v1/users/me',
            params: { user: { handicap: 10 } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['handicap']).to eq('10.0')

          user.reload
          expect(user.handicap).to eq(10.0)
        end

        it 'updates handicap with zero' do
          patch '/api/v1/users/me',
            params: { user: { handicap: 0 } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['handicap']).to eq('0.0')

          user.reload
          expect(user.handicap).to eq(0.0)
        end

        it 'allows clearing handicap' do
          user.update(handicap: 15.5)

          patch '/api/v1/users/me',
            params: { user: { handicap: nil } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['handicap']).to be_nil

          user.reload
          expect(user.handicap).to be_nil
        end

        it 'returns error for negative handicap' do
          patch '/api/v1/users/me',
            params: { user: { handicap: -5 } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json['errors']['handicap']).to include('must be greater than or equal to 0')
        end

        it 'returns error for handicap over 54' do
          patch '/api/v1/users/me',
            params: { user: { handicap: 55.0 } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json['errors']['handicap']).to include('must be less than or equal to 54.0')
        end

        it 'returns error for non-numeric handicap' do
          patch '/api/v1/users/me',
            params: { user: { handicap: 'invalid' } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json['errors']['handicap']).to include('is not a number')
        end
      end

      context 'updating multiple fields' do
        it 'updates name, venmo_handle, and handicap together' do
          patch '/api/v1/users/me',
            params: {
              user: {
                name: 'Updated Name',
                venmo_handle: '@updated',
                handicap: 12.5
              }
            },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['name']).to eq('Updated Name')
          expect(json['venmo_handle']).to eq('@updated')
          expect(json['handicap']).to eq('12.5')

          user.reload
          expect(user.name).to eq('Updated Name')
          expect(user.venmo_handle).to eq('@updated')
          expect(user.handicap).to eq(12.5)
        end

        it 'updates profile with location preferences' do
          patch '/api/v1/users/me',
            params: {
              user: {
                name: 'Updated Name',
                venmo_handle: '@updated',
                handicap: 12.5,
                home_zip_code: '94102',
                preferred_radius_miles: 50
              }
            },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['name']).to eq('Updated Name')
          expect(json['venmo_handle']).to eq('@updated')
          expect(json['handicap']).to eq('12.5')
          expect(json['home_zip_code']).to eq('94102')
          expect(json['preferred_radius_miles']).to eq(50)

          user.reload
          expect(user.name).to eq('Updated Name')
          expect(user.venmo_handle).to eq('@updated')
          expect(user.handicap).to eq(12.5)
          expect(user.home_zip_code).to eq('94102')
          expect(user.preferred_radius_miles).to eq(50)
        end
      end

      context 'updating name' do
        it 'updates name' do
          patch '/api/v1/users/me',
            params: { user: { name: 'New Name' } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['name']).to eq('New Name')

          user.reload
          expect(user.name).to eq('New Name')
        end

        it 'returns error when name is blank' do
          patch '/api/v1/users/me',
            params: { user: { name: '' } },
            headers: auth_headers,
            as: :json

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json['errors']['name']).to include("can't be blank")
        end
      end

      context 'partial updates' do
        before do
          user.update(name: 'Original Name', venmo_handle: '@original', handicap: 10.0)
        end

        it 'updates only venmo_handle without affecting other fields' do
          patch '/api/v1/users/me',
            params: { user: { venmo_handle: '@changed' } },
            headers: auth_headers,
            as: :json

          user.reload
          expect(user.name).to eq('Original Name')
          expect(user.venmo_handle).to eq('@changed')
          expect(user.handicap).to eq(10.0)
        end

        it 'updates only handicap without affecting other fields' do
          patch '/api/v1/users/me',
            params: { user: { handicap: 20.5 } },
            headers: auth_headers,
            as: :json

          user.reload
          expect(user.name).to eq('Original Name')
          expect(user.venmo_handle).to eq('@original')
          expect(user.handicap).to eq(20.5)
        end
      end
    end

    context 'without authentication' do
      it 'returns unauthorized error' do
        patch '/api/v1/users/me',
          params: { user: { name: 'New Name' } },
          as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized error' do
        patch '/api/v1/users/me',
          params: { user: { name: 'New Name' } },
          headers: { 'Authorization' => 'Bearer invalid_token' },
          as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
