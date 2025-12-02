require 'rails_helper'

RSpec.describe GoogleAuthService do
  let(:valid_token) { 'valid_google_id_token_123' }
  let(:invalid_token) { 'invalid_token' }

  let(:valid_payload) do
    {
      'iss' => 'https://accounts.google.com',
      'sub' => '1234567890',
      'email' => 'user@example.com',
      'email_verified' => true,
      'name' => 'John Doe',
      'given_name' => 'John',
      'family_name' => 'Doe',
      'picture' => 'https://example.com/photo.jpg',
      'aud' => ENV['GOOGLE_CLIENT_ID'] || 'test_client_id'
    }
  end

  describe '.verify_token' do
    context 'with valid token' do
      before do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc)
          .with(valid_token, aud: anything)
          .and_return(valid_payload)
      end

      it 'returns the payload' do
        result = described_class.verify_token(valid_token)
        expect(result).to be_a(Hash)
        expect(result['email']).to eq('user@example.com')
      end

      it 'returns user info from payload' do
        result = described_class.verify_token(valid_token)
        expect(result['sub']).to eq('1234567890')
        expect(result['name']).to eq('John Doe')
        expect(result['picture']).to eq('https://example.com/photo.jpg')
      end

      it 'verifies email is verified' do
        result = described_class.verify_token(valid_token)
        expect(result['email_verified']).to be true
      end
    end

    context 'with invalid token' do
      before do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc)
          .with(invalid_token, aud: anything)
          .and_raise(Google::Auth::IDTokens::VerificationError.new('Invalid token'))
      end

      it 'raises VerificationError' do
        expect {
          described_class.verify_token(invalid_token)
        }.to raise_error(Google::Auth::IDTokens::VerificationError)
      end
    end

    context 'when token verification returns nil' do
      before do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc)
          .with(valid_token, aud: anything)
          .and_return(nil)
      end

      it 'raises StandardError' do
        expect {
          described_class.verify_token(valid_token)
        }.to raise_error(StandardError, 'Invalid Google ID token')
      end
    end
  end

  describe '.extract_user_info' do
    it 'extracts user information from valid payload' do
      info = described_class.extract_user_info(valid_payload)

      expect(info[:google_id]).to eq('1234567890')
      expect(info[:email]).to eq('user@example.com')
      expect(info[:name]).to eq('John Doe')
      expect(info[:given_name]).to eq('John')
      expect(info[:family_name]).to eq('Doe')
      expect(info[:picture]).to eq('https://example.com/photo.jpg')
      expect(info[:email_verified]).to be true
    end

    it 'handles missing optional fields' do
      minimal_payload = {
        'sub' => '1234567890',
        'email' => 'user@example.com',
        'email_verified' => true,
        'name' => 'John Doe'
      }

      info = described_class.extract_user_info(minimal_payload)
      expect(info[:google_id]).to eq('1234567890')
      expect(info[:email]).to eq('user@example.com')
      expect(info[:name]).to eq('John Doe')
      expect(info[:given_name]).to be_nil
      expect(info[:family_name]).to be_nil
      expect(info[:picture]).to be_nil
    end
  end
end
