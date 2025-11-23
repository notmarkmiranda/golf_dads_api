require 'rails_helper'

RSpec.describe GoogleTokenVerifier do
  let(:valid_token) { 'valid_google_token_123' }
  let(:invalid_token) { 'invalid_token' }

  let(:valid_payload) do
    {
      'iss' => 'https://accounts.google.com',
      'sub' => '1234567890',
      'email' => 'user@example.com',
      'email_verified' => true,
      'name' => 'John Doe',
      'picture' => 'https://example.com/photo.jpg',
      'aud' => ENV['GOOGLE_CLIENT_ID'] || 'test_client_id'
    }
  end

  describe '.verify' do
    context 'with valid token' do
      before do
        allow(GoogleIDToken::Validator).to receive(:new).and_return(
          double(check: valid_payload)
        )
      end

      it 'returns the payload' do
        result = described_class.verify(valid_token)
        expect(result).to be_a(Hash)
        expect(result['email']).to eq('user@example.com')
      end

      it 'returns user info from payload' do
        result = described_class.verify(valid_token)
        expect(result['sub']).to eq('1234567890')
        expect(result['name']).to eq('John Doe')
        expect(result['picture']).to eq('https://example.com/photo.jpg')
      end

      it 'verifies email is verified' do
        result = described_class.verify(valid_token)
        expect(result['email_verified']).to be true
      end
    end

    context 'with invalid token' do
      before do
        allow(GoogleIDToken::Validator).to receive(:new).and_return(
          double(check: nil)
        )
      end

      it 'returns nil' do
        expect(described_class.verify(invalid_token)).to be_nil
      end
    end

    context 'when token verification raises an error' do
      before do
        allow(GoogleIDToken::Validator).to receive(:new).and_raise(StandardError.new('Verification failed'))
      end

      it 'returns nil' do
        expect(described_class.verify(valid_token)).to be_nil
      end
    end

    context 'when email is not verified' do
      before do
        unverified_payload = valid_payload.merge('email_verified' => false)
        allow(GoogleIDToken::Validator).to receive(:new).and_return(
          double(check: unverified_payload)
        )
      end

      it 'returns nil' do
        expect(described_class.verify(valid_token)).to be_nil
      end
    end
  end

  describe '.extract_user_info' do
    it 'extracts user information from valid payload' do
      info = described_class.extract_user_info(valid_payload)

      expect(info[:uid]).to eq('1234567890')
      expect(info[:email]).to eq('user@example.com')
      expect(info[:name]).to eq('John Doe')
      expect(info[:avatar_url]).to eq('https://example.com/photo.jpg')
      expect(info[:provider]).to eq('google')
    end

    it 'handles missing optional fields' do
      minimal_payload = {
        'sub' => '1234567890',
        'email' => 'user@example.com',
        'name' => 'John Doe'
      }

      info = described_class.extract_user_info(minimal_payload)
      expect(info[:uid]).to eq('1234567890')
      expect(info[:email]).to eq('user@example.com')
      expect(info[:name]).to eq('John Doe')
      expect(info[:avatar_url]).to be_nil
      expect(info[:provider]).to eq('google')
    end
  end
end
