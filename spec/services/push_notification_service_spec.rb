require 'rails_helper'

RSpec.describe PushNotificationService, type: :service do
  let(:user) { create(:user) }
  let(:device_token) { create(:device_token, user: user) }

  before do
    # Stub FCM configuration and client for all tests
    stub_const('FCM_CONFIG', { project_id: 'test-project', credentials_path: 'config/test-credentials.json' })
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(Rails.root.join('config/test-credentials.json')).and_return(true)
    allow(PushNotificationService).to receive(:fcm_client).and_return(double(send_v1: { status_code: 200 }))
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
end
