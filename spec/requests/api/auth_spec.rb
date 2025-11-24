require 'rails_helper'

RSpec.describe 'Api::Auth', type: :request do
  describe 'POST /api/auth/signup' do
    let(:valid_params) do
      {
        user: {
          email: 'newuser@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          name: 'New User'
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post '/api/auth/signup', params: valid_params, as: :json
        }.to change(User, :count).by(1)
      end

      it 'returns a JWT token' do
        post '/api/auth/signup', params: valid_params, as: :json
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['token']).to be_present
        expect(json['token'].split('.').length).to eq(3)
      end

      it 'returns user data' do
        post '/api/auth/signup', params: valid_params, as: :json
        json = JSON.parse(response.body)
        expect(json['user']).to be_present
        expect(json['user']['email']).to eq('newuser@example.com')
        expect(json['user']['name']).to eq('New User')
        expect(json['user']['id']).to be_present
      end

      it 'does not return password_digest' do
        post '/api/auth/signup', params: valid_params, as: :json
        json = JSON.parse(response.body)
        expect(json['user']['password_digest']).to be_nil
      end

      it 'token contains user_id' do
        post '/api/auth/signup', params: valid_params, as: :json
        json = JSON.parse(response.body)
        decoded = JsonWebToken.decode(json['token'])
        expect(decoded['user_id']).to eq(User.last.id)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when email is missing' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:email] = ''
        post '/api/auth/signup', params: invalid_params, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
        expect(json['errors']['email_address']).to include("can't be blank")
      end

      it 'returns error when password is too short' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:password] = '123'
        invalid_params[:user][:password_confirmation] = '123'
        post '/api/auth/signup', params: invalid_params, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']['password']).to include('is too short (minimum is 8 characters)')
      end

      it 'returns error when email is already taken' do
        create(:user, email_address: 'newuser@example.com')
        post '/api/auth/signup', params: valid_params, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']['email_address']).to include('has already been taken')
      end

      it 'returns error when name is missing' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:name] = ''
        post '/api/auth/signup', params: invalid_params, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']['name']).to include("can't be blank")
      end
    end
  end

  describe 'POST /api/auth/login' do
    let!(:user) { create(:user, email_address: 'user@example.com', password: 'password123') }

    let(:valid_params) do
      {
        email: 'user@example.com',
        password: 'password123'
      }
    end

    context 'with valid credentials' do
      it 'returns a JWT token' do
        post '/api/auth/login', params: valid_params, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['token']).to be_present
        expect(json['token'].split('.').length).to eq(3)
      end

      it 'returns user data' do
        post '/api/auth/login', params: valid_params, as: :json
        json = JSON.parse(response.body)
        expect(json['user']).to be_present
        expect(json['user']['email']).to eq('user@example.com')
        expect(json['user']['name']).to be_present
        expect(json['user']['id']).to eq(user.id)
      end

      it 'does not return password_digest' do
        post '/api/auth/login', params: valid_params, as: :json
        json = JSON.parse(response.body)
        expect(json['user']['password_digest']).to be_nil
      end

      it 'token contains user_id' do
        post '/api/auth/login', params: valid_params, as: :json
        json = JSON.parse(response.body)
        decoded = JsonWebToken.decode(json['token'])
        expect(decoded['user_id']).to eq(user.id)
      end

      it 'accepts case-insensitive email' do
        post '/api/auth/login', params: { email: 'USER@EXAMPLE.COM', password: 'password123' }, as: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid credentials' do
      it 'returns error with wrong password' do
        post '/api/auth/login', params: { email: 'user@example.com', password: 'wrongpassword' }, as: :json
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid email or password')
      end

      it 'returns error with non-existent email' do
        post '/api/auth/login', params: { email: 'nonexistent@example.com', password: 'password123' }, as: :json
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid email or password')
      end

      it 'returns error when email is missing' do
        post '/api/auth/login', params: { password: 'password123' }, as: :json
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid email or password')
      end

      it 'returns error when password is missing' do
        post '/api/auth/login', params: { email: 'user@example.com' }, as: :json
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid email or password')
      end
    end
  end

  describe 'POST /api/auth/google' do
    let(:valid_google_token) { 'valid_google_token_123' }
    let(:invalid_google_token) { 'invalid_google_token' }

    let(:google_payload) do
      {
        'sub' => 'google_user_123',
        'email' => 'googleuser@example.com',
        'name' => 'Google User',
        'picture' => 'https://example.com/avatar.jpg',
        'email_verified' => true
      }
    end

    context 'with valid Google token' do
      before do
        allow(GoogleTokenVerifier).to receive(:verify).with(valid_google_token).and_return(google_payload)
        allow(GoogleTokenVerifier).to receive(:extract_user_info).with(google_payload).and_return({
          uid: 'google_user_123',
          email: 'googleuser@example.com',
          name: 'Google User',
          avatar_url: 'https://example.com/avatar.jpg',
          provider: 'google'
        })
      end

      context 'when user does not exist' do
        it 'creates a new user' do
          expect {
            post '/api/auth/google', params: { token: valid_google_token }, as: :json
          }.to change(User, :count).by(1)
        end

        it 'returns a JWT token' do
          post '/api/auth/google', params: { token: valid_google_token }, as: :json
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['token']).to be_present
          expect(json['token'].split('.').length).to eq(3)
        end

        it 'returns user data with OAuth provider' do
          post '/api/auth/google', params: { token: valid_google_token }, as: :json
          json = JSON.parse(response.body)
          expect(json['user']['email']).to eq('googleuser@example.com')
          expect(json['user']['name']).to eq('Google User')
          expect(json['user']['provider']).to eq('google')
          expect(json['user']['avatar_url']).to eq('https://example.com/avatar.jpg')
        end

        it 'does not set password_digest for OAuth user' do
          post '/api/auth/google', params: { token: valid_google_token }, as: :json
          user = User.last
          expect(user.password_digest).to be_nil
        end
      end

      context 'when user already exists' do
        before do
          User.create!(
            provider: 'google',
            uid: 'google_user_123',
            email_address: 'googleuser@example.com',
            name: 'Old Name'
          )
        end

        it 'does not create a new user' do
          expect {
            post '/api/auth/google', params: { token: valid_google_token }, as: :json
          }.not_to change(User, :count)
        end

        it 'updates existing user information' do
          post '/api/auth/google', params: { token: valid_google_token }, as: :json
          user = User.find_by(provider: 'google', uid: 'google_user_123')
          expect(user.name).to eq('Google User')
          expect(user.avatar_url).to eq('https://example.com/avatar.jpg')
        end

        it 'returns a JWT token' do
          post '/api/auth/google', params: { token: valid_google_token }, as: :json
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['token']).to be_present
        end
      end
    end

    context 'with invalid Google token' do
      before do
        allow(GoogleTokenVerifier).to receive(:verify).with(invalid_google_token).and_return(nil)
      end

      it 'returns error' do
        post '/api/auth/google', params: { token: invalid_google_token }, as: :json
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid Google token')
      end

      it 'does not create a user' do
        expect {
          post '/api/auth/google', params: { token: invalid_google_token }, as: :json
        }.not_to change(User, :count)
      end
    end

    context 'with missing token' do
      it 'returns error' do
        post '/api/auth/google', params: {}, as: :json
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid Google token')
      end
    end
  end
end
