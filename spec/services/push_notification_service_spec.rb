require 'rails_helper'

RSpec.describe PushNotificationService, type: :service do
  let(:user) { create(:user) }
  let(:device_token) { create(:device_token, user: user) }

  before do
    # Stub FCM configuration and service for all tests
    stub_const('FCM_CONFIG', { project_id: 'test-project', credentials_path: 'config/test-credentials.json' })
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(Rails.root.join('config/test-credentials.json')).and_return(true)

    # Mock the send_fcm_notification method to return success
    allow(PushNotificationService).to receive(:send_fcm_notification).and_return(
      { success: true, error: nil, invalid_tokens: [] }
    )
  end

  describe '.send_to_user' do
    let(:title) { 'Test Notification' }
    let(:body) { 'Test body' }
    let(:data) { { tee_time_id: 123 } }
    let(:notification_type) { :reservation_created }

    before do
      device_token # Ensure user has device token
    end

    context 'when user has notification preferences enabled' do
      it 'sends notification successfully' do
        result = PushNotificationService.send_to_user(
          user,
          title: title,
          body: body,
          data: data,
          notification_type: notification_type
        )

        expect(result).to be true
      end

      it 'creates a notification log' do
        expect {
          PushNotificationService.send_to_user(
            user,
            title: title,
            body: body,
            data: data,
            notification_type: notification_type
          )
        }.to change { NotificationLog.count }.by(1)
      end

      it 'marks notification log as sent' do
        PushNotificationService.send_to_user(
          user,
          title: title,
          body: body,
          data: data,
          notification_type: notification_type
        )

        log = NotificationLog.last
        expect(log.status).to eq('sent')
        expect(log.sent_at).to be_present
      end
    end

    context 'when user has notification preferences disabled' do
      before do
        user.notification_preference.update!(reservations_enabled: false)
      end

      it 'does not send notification' do
        result = PushNotificationService.send_to_user(
          user,
          title: title,
          body: body,
          data: data,
          notification_type: notification_type
        )

        expect(result).to be false
      end

      it 'does not create notification log' do
        expect {
          PushNotificationService.send_to_user(
            user,
            title: title,
            body: body,
            data: data,
            notification_type: notification_type
          )
        }.not_to change { NotificationLog.count }
      end
    end

    context 'when user has no device tokens' do
      before do
        user.device_tokens.destroy_all
      end

      it 'returns false' do
        result = PushNotificationService.send_to_user(
          user,
          title: title,
          body: body,
          data: data,
          notification_type: notification_type
        )

        expect(result).to be false
      end
    end
  end

  describe '.send_to_users' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let!(:token1) { create(:device_token, user: user1) }
    let!(:token2) { create(:device_token, user: user2) }

    it 'sends notifications to all users' do
      result = PushNotificationService.send_to_users(
        [ user1, user2 ],
        title: 'Test',
        body: 'Test body',
        data: {},
        notification_type: :group_tee_time
      )

      expect(result[:success_count]).to eq(2)
      expect(result[:failure_count]).to eq(0)
    end

    it 'tracks failures' do
      # Make one user fail
      user2.notification_preference.update!(group_activity_enabled: false)

      result = PushNotificationService.send_to_users(
        [ user1, user2 ],
        title: 'Test',
        body: 'Test body',
        data: {},
        notification_type: :group_tee_time
      )

      expect(result[:success_count]).to eq(1)
      expect(result[:failure_count]).to eq(1)
    end
  end

  describe '.format_tee_time_for_device' do
    let(:user) { create(:user) }
    let(:tee_time) { Time.utc(2025, 12, 25, 17, 15) } # 5:15pm UTC (Dec 25)

    context 'with device timezone set' do
      it 'formats time in Mountain Time without timezone suffix' do
        device_token = create(:device_token, user: user, timezone: 'America/Denver')
        result = PushNotificationService.format_tee_time_for_device(tee_time, device_token)

        # 5:15pm UTC = 10:15am MST
        expect(result).to eq('Dec 25 at 10:15am')
        expect(result).not_to include('UTC')
      end

      it 'formats time in Pacific Time without timezone suffix' do
        device_token = create(:device_token, user: user, timezone: 'America/Los_Angeles')
        result = PushNotificationService.format_tee_time_for_device(tee_time, device_token)

        # 5:15pm UTC = 9:15am PST
        expect(result).to eq('Dec 25 at 9:15am')
        expect(result).not_to include('UTC')
      end

      it 'formats time in Eastern Time without timezone suffix' do
        device_token = create(:device_token, user: user, timezone: 'America/New_York')
        result = PushNotificationService.format_tee_time_for_device(tee_time, device_token)

        # 5:15pm UTC = 12:15pm EST
        expect(result).to eq('Dec 25 at 12:15pm')
        expect(result).not_to include('UTC')
      end

      it 'handles times after midnight in local timezone' do
        late_time = Time.utc(2025, 12, 26, 6, 30) # 6:30am UTC (Dec 26)
        device_token = create(:device_token, user: user, timezone: 'America/Denver')
        result = PushNotificationService.format_tee_time_for_device(late_time, device_token)

        # 6:30am UTC Dec 26 = 11:30pm MST Dec 25
        expect(result).to eq('Dec 25 at 11:30pm')
      end

      it 'formats single-digit hours without leading zero' do
        morning_time = Time.utc(2025, 12, 25, 15, 5) # 3:05pm UTC
        device_token = create(:device_token, user: user, timezone: 'America/Denver')
        result = PushNotificationService.format_tee_time_for_device(morning_time, device_token)

        # 3:05pm UTC = 8:05am MST
        expect(result).to eq('Dec 25 at 8:05am')
        expect(result).not_to match(/08:05/) # Should not have leading zero
      end
    end

    context 'without device timezone (backward compatibility)' do
      it 'formats time in UTC with UTC suffix' do
        device_token = create(:device_token, user: user, timezone: nil)
        result = PushNotificationService.format_tee_time_for_device(tee_time, device_token)

        expect(result).to eq('Dec 25 at 5:15pm UTC')
        expect(result).to include('UTC')
      end

      it 'formats time in UTC with blank timezone' do
        device_token = create(:device_token, user: user, timezone: '')
        result = PushNotificationService.format_tee_time_for_device(tee_time, device_token)

        expect(result).to eq('Dec 25 at 5:15pm UTC')
        expect(result).to include('UTC')
      end
    end

    context 'with different dates' do
      it 'formats January date correctly' do
        jan_time = Time.utc(2025, 1, 15, 17, 15)
        device_token = create(:device_token, user: user, timezone: 'America/Denver')
        result = PushNotificationService.format_tee_time_for_device(jan_time, device_token)

        expect(result).to eq('Jan 15 at 10:15am')
      end

      it 'formats single-digit day without leading zero' do
        single_day = Time.utc(2025, 3, 5, 17, 15)
        device_token = create(:device_token, user: user, timezone: 'America/Denver')
        result = PushNotificationService.format_tee_time_for_device(single_day, device_token)

        expect(result).to eq('Mar 5 at 10:15am')
        expect(result).not_to match(/Mar 05/) # Should not have leading zero
      end
    end
  end
end
