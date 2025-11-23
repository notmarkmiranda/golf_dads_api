require 'rails_helper'

RSpec.describe JsonWebToken do
  let(:payload) { { user_id: 1 } }
  let(:token) { described_class.encode(payload) }

  describe '.encode' do
    it 'returns a JWT token' do
      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3) # JWT has 3 parts
    end

    it 'includes the payload in the token' do
      decoded = JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: 'HS256')
      expect(decoded.first['user_id']).to eq(1)
    end

    it 'sets expiration time to 24 hours from now' do
      decoded = JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: 'HS256')
      exp_time = Time.at(decoded.first['exp'])
      expect(exp_time).to be_within(5.seconds).of(24.hours.from_now)
    end

    it 'accepts custom expiration time' do
      custom_token = described_class.encode(payload, exp: 2.hours.from_now.to_i)
      decoded = JWT.decode(custom_token, Rails.application.credentials.secret_key_base, true, algorithm: 'HS256')
      exp_time = Time.at(decoded.first['exp'])
      expect(exp_time).to be_within(5.seconds).of(2.hours.from_now)
    end
  end

  describe '.decode' do
    context 'with valid token' do
      it 'returns the decoded payload' do
        result = described_class.decode(token)
        expect(result).to be_a(Hash)
        expect(result['user_id']).to eq(1)
      end

      it 'returns payload with string keys' do
        result = described_class.decode(token)
        expect(result.keys).to all(be_a(String))
      end
    end

    context 'with expired token' do
      let(:expired_token) do
        described_class.encode(payload, exp: 1.hour.ago.to_i)
      end

      it 'returns nil' do
        expect(described_class.decode(expired_token)).to be_nil
      end
    end

    context 'with invalid token' do
      it 'returns nil for malformed token' do
        expect(described_class.decode('invalid.token')).to be_nil
      end

      it 'returns nil for token with wrong signature' do
        wrong_token = JWT.encode(payload, 'wrong_secret', 'HS256')
        expect(described_class.decode(wrong_token)).to be_nil
      end

      it 'returns nil for nil token' do
        expect(described_class.decode(nil)).to be_nil
      end

      it 'returns nil for empty string' do
        expect(described_class.decode('')).to be_nil
      end
    end
  end
end
