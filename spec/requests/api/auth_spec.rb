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
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
        expect(json['errors']['email_address']).to include("can't be blank")
      end

      it 'returns error when password is too short' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:password] = '123'
        invalid_params[:user][:password_confirmation] = '123'
        post '/api/auth/signup', params: invalid_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']['password']).to include('is too short (minimum is 8 characters)')
      end

      it 'returns error when email is already taken' do
        create(:user, email_address: 'newuser@example.com')
        post '/api/auth/signup', params: valid_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']['email_address']).to include('has already been taken')
      end

      it 'returns error when name is missing' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:name] = ''
        post '/api/auth/signup', params: invalid_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
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
end
