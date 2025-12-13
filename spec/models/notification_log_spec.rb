require 'rails_helper'

RSpec.describe NotificationLog, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:notification_log) }

    it { should validate_presence_of(:notification_type) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:body) }

    it do
      should validate_inclusion_of(:notification_type).in_array(%w[
        reservation_created
        reservation_cancelled
        group_tee_time
        reminder_24h
        reminder_2h
      ])
    end

    it { should validate_inclusion_of(:status).in_array(%w[pending sent failed]) }
  end

  describe 'default values' do
    let(:user) { create(:user) }

    it 'defaults status to pending' do
      log = create(:notification_log, user: user)
      expect(log.status).to eq('pending')
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }

    describe '.pending' do
      it 'returns pending notifications' do
        pending_log = create(:notification_log, user: user, status: 'pending')
        sent_log = create(:notification_log, user: user, status: 'sent')

        expect(NotificationLog.pending).to include(pending_log)
        expect(NotificationLog.pending).not_to include(sent_log)
      end
    end

    describe '.sent' do
      it 'returns sent notifications' do
        pending_log = create(:notification_log, user: user, status: 'pending')
        sent_log = create(:notification_log, user: user, status: 'sent')

        expect(NotificationLog.sent).to include(sent_log)
        expect(NotificationLog.sent).not_to include(pending_log)
      end
    end

    describe '.failed' do
      it 'returns failed notifications' do
        pending_log = create(:notification_log, user: user, status: 'pending')
        failed_log = create(:notification_log, user: user, status: 'failed')

        expect(NotificationLog.failed).to include(failed_log)
        expect(NotificationLog.failed).not_to include(pending_log)
      end
    end

    describe '.recent' do
      it 'orders by created_at descending' do
        old_log = nil
        new_log = nil

        travel_to 2.days.ago do
          old_log = create(:notification_log, user: user)
        end

        travel_to 1.day.ago do
          new_log = create(:notification_log, user: user, notification_type: 'reminder_2h')
        end

        expect(NotificationLog.recent.first).to eq(new_log)
        expect(NotificationLog.recent.last).to eq(old_log)
      end
    end
  end

  describe '#mark_as_sent!' do
    let(:user) { create(:user) }
    let(:log) { create(:notification_log, user: user, status: 'pending') }

    it 'updates status to sent' do
      freeze_time do
        log.mark_as_sent!
        expect(log.reload.status).to eq('sent')
        expect(log.sent_at).to eq(Time.current)
      end
    end
  end

  describe '#mark_as_failed!' do
    let(:user) { create(:user) }
    let(:log) { create(:notification_log, user: user, status: 'pending') }

    it 'updates status to failed with error message' do
      error = StandardError.new('FCM token invalid')
      log.mark_as_failed!(error)

      expect(log.reload.status).to eq('failed')
      expect(log.error_message).to eq('FCM token invalid')
    end

    it 'handles error objects' do
      error = StandardError.new('Network timeout')
      log.mark_as_failed!(error)

      expect(log.reload.error_message).to eq('Network timeout')
    end
  end
end
