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

    describe 'timezone validation' do
      it 'accepts valid IANA timezone identifiers' do
        device_token = build(:device_token, timezone: 'America/Denver')
        expect(device_token).to be_valid
      end

      it 'accepts nil timezone' do
        device_token = build(:device_token, timezone: nil)
        expect(device_token).to be_valid
      end

      it 'accepts blank timezone' do
        device_token = build(:device_token, timezone: '')
        expect(device_token).to be_valid
      end

      it 'rejects invalid timezone identifiers' do
        device_token = build(:device_token, timezone: 'Invalid/Timezone')
        expect(device_token).not_to be_valid
        expect(device_token.errors[:timezone]).to include('is not a valid timezone identifier')
      end

      it 'accepts various valid timezones' do
        valid_timezones = [
          'America/New_York',
          'America/Los_Angeles',
          'America/Chicago',
          'Europe/London',
          'Asia/Tokyo',
          'Pacific/Auckland'
        ]

        valid_timezones.each do |tz|
          device_token = build(:device_token, timezone: tz)
          expect(device_token).to be_valid, "Expected #{tz} to be valid"
        end
      end
    end
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

  describe '#time_zone' do
    let(:user) { create(:user) }

    it 'returns TimeZone object for valid timezone' do
      device_token = create(:device_token, user: user, timezone: 'America/Denver')
      time_zone = device_token.time_zone

      expect(time_zone).to be_a(ActiveSupport::TimeZone)
      expect(time_zone.name).to eq('America/Denver')
    end

    it 'returns nil for nil timezone' do
      device_token = create(:device_token, user: user, timezone: nil)
      expect(device_token.time_zone).to be_nil
    end

    it 'returns nil for blank timezone' do
      device_token = create(:device_token, user: user, timezone: '')
      expect(device_token.time_zone).to be_nil
    end

    it 'handles various timezone formats' do
      timezones = {
        'America/New_York' => 'America/New_York',
        'America/Los_Angeles' => 'America/Los_Angeles',
        'UTC' => 'UTC',
        'Europe/London' => 'Europe/London'
      }

      timezones.each do |input, expected_name|
        device_token = create(:device_token, user: user, token: "token_#{input}", timezone: input)
        expect(device_token.time_zone.name).to eq(expected_name)
      end
    end
  end
end
