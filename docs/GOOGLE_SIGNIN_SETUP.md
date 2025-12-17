# Google Sign-In Setup Guide - Rails API

This guide walks through implementing Google Sign-In authentication for the Golf Dads Rails API backend.

## Prerequisites

- Ruby 3.x
- Rails 8.x
- Google Cloud Console account with OAuth credentials
- `googleauth` gem (Google's official authentication library)

## Overview

The Google Sign-In flow works as follows:

1. **iOS App**: User taps "Sign in with Google"
2. **iOS App**: Google SDK presents OAuth flow and returns ID token
3. **iOS App**: Sends ID token to Rails API: `POST /api/v1/auth/google`
4. **Rails API**: Verifies ID token with Google
5. **Rails API**: Finds or creates user account
6. **Rails API**: Generates JWT token
7. **Rails API**: Returns JWT token and user data to iOS app

## Step 1: Google Cloud Console Setup

### 1.1 Get Your iOS Client ID

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Select your project
3. Find your **iOS application** OAuth client
4. Copy the **Client ID**

**Important**: The Rails API now uses the **iOS Client ID** (the same one configured in your iOS app). This is required for proper token verification with the `googleauth` gem.

**Format**: `XXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com`

Example: `714139606616-6h0ah0ri87a6kb2p2a5lnqg7p690q3id.apps.googleusercontent.com`

## Step 2: Install Dependencies

### 2.1 Add Gem

Add to your `Gemfile`:

```ruby
# Google Sign-In token verification (official Google library)
gem 'googleauth', '~> 1.11'
```

Run:
```bash
bundle install
```

**Note**: We use the official `googleauth` gem instead of the deprecated `google-id-token` gem. The `googleauth` gem is actively maintained by Google and provides the `Google::Auth::IDTokens.verify_oidc` method for verifying ID tokens.

## Step 3: Configure Environment Variables

### 3.1 Add to .env

```bash
GOOGLE_CLIENT_ID=YOUR_IOS_CLIENT_ID_HERE.apps.googleusercontent.com
```

**Important**: Use the **iOS Client ID** (the same one configured in your iOS app's Info.plist).

### 3.2 Add to credentials.yml.enc (Production)

For production, use Rails encrypted credentials:

```bash
rails credentials:edit
```

Add:
```yaml
google:
  client_id: YOUR_IOS_CLIENT_ID_HERE.apps.googleusercontent.com
```

## Step 4: Create Google Auth Service

Create `app/services/google_auth_service.rb`:

```ruby
# app/services/google_auth_service.rb
require 'googleauth/id_tokens'

class GoogleAuthService
  class << self
    # Verify Google ID token and return payload
    # @param id_token [String] The Google ID token from iOS app
    # @return [Hash] The verified token payload
    # @raise [Google::Auth::IDTokens::VerificationError] If token is invalid
    def verify_token(id_token)
      client_id = google_client_id

      Rails.logger.info "Verifying Google token with client_id: #{client_id}"

      begin
        # Use Google's official googleauth gem to verify the token
        payload = Google::Auth::IDTokens.verify_oidc(id_token, aud: client_id)

        if payload
          Rails.logger.info "Token verified successfully for user: #{payload['email']}"
          # Token is valid, return payload
          payload
        else
          Rails.logger.error "Token validation returned nil"
          raise StandardError, 'Invalid Google ID token'
        end
      rescue Google::Auth::IDTokens::VerificationError => e
        Rails.logger.error "Google token verification failed: #{e.class} - #{e.message}"
        raise e
      rescue StandardError => e
        Rails.logger.error "Unexpected error during token verification: #{e.class} - #{e.message}"
        raise e
      end
    end

    # Extract user info from verified token payload
    # @param payload [Hash] The verified token payload
    # @return [Hash] User information
    def extract_user_info(payload)
      {
        google_id: payload['sub'],           # Google user ID (unique identifier)
        email: payload['email'],              # User's email
        email_verified: payload['email_verified'],
        name: payload['name'],                # Full name
        given_name: payload['given_name'],    # First name
        family_name: payload['family_name'],  # Last name
        picture: payload['picture']           # Profile picture URL
      }
    end

    private

    def google_client_id
      # Try environment variable first (development)
      return ENV['GOOGLE_CLIENT_ID'] if ENV['GOOGLE_CLIENT_ID'].present?

      # Fall back to credentials (production)
      Rails.application.credentials.dig(:google, :client_id)
    end
  end
end
```

## Step 5: Update User Model

### 5.1 Add Migration for Google ID

Generate migration:
```bash
rails generate migration AddGoogleIdToUsers google_id:string:index
```

Edit the migration:
```ruby
class AddGoogleIdToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :google_id, :string
    add_index :users, :google_id, unique: true
  end
end
```

Run migration:
```bash
rails db:migrate
```

### 5.2 Update User Model

Update `app/models/user.rb`:

```ruby
class User < ApplicationRecord
  # Existing validations
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  # Google Sign-In users don't have passwords
  has_secure_password validations: false

  # Validate password only if it's present (traditional sign-up)
  validates :password, length: { minimum: 6 }, allow_nil: true, if: :password_digest_changed?

  # Validate google_id uniqueness if present
  validates :google_id, uniqueness: true, allow_nil: true

  # Class method to find or create user from Google auth
  def self.from_google_auth(user_info)
    # First try to find by google_id
    user = find_by(google_id: user_info[:google_id])
    return user if user

    # If not found, try to find by email
    user = find_by(email: user_info[:email])

    if user
      # Link existing email/password account to Google
      user.update(google_id: user_info[:google_id])
      user
    else
      # Create new user from Google auth
      create!(
        google_id: user_info[:google_id],
        email: user_info[:email],
        name: user_info[:name],
        # No password needed for Google auth users
        password_digest: nil
      )
    end
  end

  # Check if user signed up with Google
  def google_user?
    google_id.present?
  end
end
```

## Step 6: Create Auth Controller Action

Update `app/controllers/api/v1/auth_controller.rb`:

```ruby
module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request, only: [:signup, :login, :google_signin]

      # POST /api/v1/auth/signup
      def signup
        # ... existing code ...
      end

      # POST /api/v1/auth/login
      def login
        # ... existing code ...
      end

      # POST /api/v1/auth/google
      def google_signin
        id_token = params[:idToken]

        if id_token.blank?
          render json: { error: 'ID token is required' }, status: :bad_request
          return
        end

        begin
          # Verify token with Google
          payload = GoogleAuthService.verify_token(id_token)

          # Extract user info
          user_info = GoogleAuthService.extract_user_info(payload)

          # Verify email is confirmed by Google
          unless user_info[:email_verified]
            render json: { error: 'Email not verified by Google' }, status: :unauthorized
            return
          end

          # Find or create user
          user = User.from_google_auth(user_info)

          # Generate JWT token
          token = JsonWebToken.encode(user_id: user.id)

          # Return response
          render json: {
            token: token,
            user: {
              id: user.id,
              name: user.name,
              email: user.email
            }
          }, status: :ok

        rescue Google::Auth::IDTokens::VerificationError => e
          Rails.logger.error "Google Sign-In failed: #{e.message}"
          render json: { error: 'Invalid Google ID token' }, status: :unauthorized

        rescue StandardError => e
          Rails.logger.error "Google Sign-In error: #{e.class} - #{e.message}"
          render json: { error: 'Authentication failed' }, status: :internal_server_error
        end
      end
    end
  end
end
```

## Step 7: Add Route

Update `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post 'auth/signup', to: 'auth#signup'
      post 'auth/login', to: 'auth#login'
      post 'auth/google', to: 'auth#google_signin'  # Add this line

      # ... other routes ...
    end
  end
end
```

## Step 8: Testing

### 8.1 Manual Testing with cURL

First, get a valid Google ID token from your iOS app (add logging to print it), then:

```bash
curl -X POST http://localhost:3000/api/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{
    "idToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjY..."
  }'
```

Expected success response:
```json
{
  "token": "your_jwt_token",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

### 8.2 Test Invalid Token

```bash
curl -X POST http://localhost:3000/api/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{
    "idToken": "invalid_token"
  }'
```

Expected error response:
```json
{
  "error": "Invalid Google ID token"
}
```

### 8.3 Automated Tests

Create `spec/requests/api/v1/auth_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe 'Api::V1::Auth', type: :request do
  describe 'POST /api/v1/auth/google' do
    let(:valid_token) { 'valid_google_id_token' }
    let(:valid_payload) do
      {
        'sub' => 'google_user_123',
        'email' => 'test@example.com',
        'email_verified' => true,
        'name' => 'Test User',
        'given_name' => 'Test',
        'family_name' => 'User',
        'picture' => 'https://example.com/photo.jpg'
      }
    end

    before do
      allow(GoogleAuthService).to receive(:verify_token).with(valid_token).and_return(valid_payload)
      allow(GoogleAuthService).to receive(:extract_user_info).and_return({
        google_id: 'google_user_123',
        email: 'test@example.com',
        email_verified: true,
        name: 'Test User',
        given_name: 'Test',
        family_name: 'User',
        picture: 'https://example.com/photo.jpg'
      })
    end

    context 'with valid token' do
      it 'creates a new user and returns JWT token' do
        post '/api/v1/auth/google', params: { idToken: valid_token }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['token']).to be_present
        expect(json['user']['email']).to eq('test@example.com')
        expect(json['user']['name']).to eq('Test User')
      end

      it 'links existing user if email matches' do
        existing_user = User.create!(
          email: 'test@example.com',
          name: 'Existing User',
          password: 'password123'
        )

        post '/api/v1/auth/google', params: { idToken: valid_token }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['user']['id']).to eq(existing_user.id)

        existing_user.reload
        expect(existing_user.google_id).to eq('google_user_123')
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized error' do
        allow(GoogleAuthService).to receive(:verify_token)
          .and_raise(Google::Auth::IDTokens::VerificationError.new('Invalid token'))

        post '/api/v1/auth/google', params: { idToken: 'invalid_token' }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid Google ID token')
      end
    end

    context 'without token' do
      it 'returns bad request error' do
        post '/api/v1/auth/google'

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('ID token is required')
      end
    end
  end
end
```

Run tests:
```bash
bundle exec rspec spec/requests/api/v1/auth_spec.rb
```

## Step 9: Security Considerations

### 9.1 Token Verification

Always verify tokens server-side:
- Never trust tokens without verification
- Use Google's official verification libraries
- Check token expiration and issuer

### 9.2 HTTPS Only

In production, ensure API uses HTTPS:

```ruby
# config/environments/production.rb
config.force_ssl = true
```

### 9.3 Rate Limiting

Add rate limiting to prevent abuse:

```ruby
# Use rack-attack or similar
Rack::Attack.throttle('auth/ip', limit: 5, period: 60) do |req|
  if req.path == '/api/v1/auth/google' && req.post?
    req.ip
  end
end
```

### 9.4 Environment Variables

Never commit credentials:
- Use `.env` for development (add to `.gitignore`)
- Use `credentials.yml.enc` for production
- Rotate credentials regularly

## Step 10: Deployment

### 10.1 Heroku

Set environment variable:
```bash
heroku config:set GOOGLE_CLIENT_ID=your_web_client_id
```

### 10.2 AWS/VPS

Add to your environment configuration or use encrypted credentials.

### 10.3 Database Migration

Don't forget to run migrations:
```bash
rails db:migrate
```

## Troubleshooting

### Issue: "Invalid Google ID token"

**Possible causes:**
1. Token expired (Google tokens expire in 1 hour)
2. Wrong Client ID (must use iOS Client ID that matches the token's audience claim)
3. Token from wrong Google project
4. Network issues preventing verification with Google's servers

**Solutions:**
- Log the token and payload for debugging
- Verify GOOGLE_CLIENT_ID environment variable matches iOS Client ID
- Check Google Cloud Console credentials
- Ensure token is fresh (generated recently)
- Verify the iOS app is using the correct Client ID

### Issue: "Email not verified by Google"

**Cause**: User's Google account email is not verified.

**Solution**: User must verify their email in Google account settings.

### Issue: ActiveRecord::RecordInvalid

**Cause**: User model validation failing (e.g., duplicate email).

**Solution**: Check User model validations and database constraints.

### Issue: Google::Auth::IDTokens::VerificationError

**Cause**: Token signature verification failed.

**Solutions:**
- Ensure correct iOS Client ID
- Check token hasn't expired
- Verify network connectivity to Google's verification servers
- Ensure the `googleauth` gem is properly installed

## Monitoring

### Log Important Events

```ruby
# In controller
Rails.logger.info "Google Sign-In: User #{user.id} authenticated"

# In service
Rails.logger.error "Google token verification failed: #{e.message}"
```

### Track Metrics

Monitor:
- Google sign-in success rate
- Token verification failures
- New user creation from Google auth
- Failed authentication attempts

## Additional Resources

- [Google Identity Documentation](https://developers.google.com/identity)
- [Google ID Token Verification](https://developers.google.com/identity/sign-in/web/backend-auth)
- [googleauth gem documentation](https://googleapis.dev/ruby/googleauth/latest/)
- [OAuth 2.0 for Mobile Apps](https://developers.google.com/identity/protocols/oauth2/native-app)
- [Verifying ID Tokens](https://googleapis.dev/ruby/googleauth/latest/Google/Auth/IDTokens.html)

## Support

For issues specific to:
- **Token verification**: Check Google Identity documentation
- **User model**: Review ActiveRecord validations
- **JWT generation**: Check JsonWebToken service
- **iOS integration**: See iOS app `GOOGLE_SIGNIN_SETUP.md`
