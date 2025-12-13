require 'rails_helper'

RSpec.describe DeviceToken, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:device_token) }

    it { should validate_presence_of(:token) }
    it { should validate_presence_of(:platform) }
    it { should validate_uniqueness_of(:token) }
    it { should validate_inclusion_of(:platform).in_array(%w[ios android]) }
  end

  describe 'attributes' do
    let(:user) { create(:user) }

    it 'has a token' do
      device_token = build(:device_token, token: 'abc123xyz')
      expect(device_token.token).to eq('abc123xyz')
    end

    it 'has a platform defaulting to ios' do
      device_token = create(:device_token, user: user)
      expect(device_token.platform).to eq('ios')
    end

    it 'has a last_used_at timestamp' do
      device_token = create(:device_token, user: user)
      expect(device_token.last_used_at).to be_present
    end
  end

  describe 'callbacks' do
    let(:user) { create(:user) }

    it 'updates last_used_at on create' do
      freeze_time do
        device_token = create(:device_token, user: user)
        expect(device_token.last_used_at).to eq(Time.current)
      end
    end

    it 'updates last_used_at when token changes' do
      device_token = create(:device_token, user: user)
      original_time = device_token.last_used_at

      travel 1.day do
        device_token.update!(token: 'new_token_xyz')
        expect(device_token.last_used_at).to be > original_time
      end
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }

    describe '.active' do
      it 'returns device tokens used within 30 days' do
        active_token = create(:device_token, user: user)
        active_token.update_column(:last_used_at, 10.days.ago)

        stale_token = create(:device_token, user: user, token: 'stale_token')
        stale_token.update_column(:last_used_at, 31.days.ago)

        expect(DeviceToken.active).to include(active_token)
        expect(DeviceToken.active).not_to include(stale_token)
      end
    end

    describe '.stale' do
      it 'returns device tokens not used in 30 days' do
        active_token = create(:device_token, user: user)
        active_token.update_column(:last_used_at, 10.days.ago)

        stale_token = create(:device_token, user: user, token: 'stale_token')
        stale_token.update_column(:last_used_at, 31.days.ago)

        expect(DeviceToken.stale).to include(stale_token)
        expect(DeviceToken.stale).not_to include(active_token)
      end

      it 'includes tokens with nil last_used_at' do
        device_token = create(:device_token, user: user)
        device_token.update_column(:last_used_at, nil)

        expect(DeviceToken.stale).to include(device_token)
      end
    end
  end
end
