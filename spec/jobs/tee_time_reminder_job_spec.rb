require 'rails_helper'

RSpec.describe TeeTimeReminderJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  let(:owner) { create(:user, name: 'Owner') }
  let(:reserver1) { create(:user, name: 'Reserver 1') }
  let(:reserver2) { create(:user, name: 'Reserver 2') }
  let(:golf_course) { create(:golf_course, name: 'Test Course') }

  before do
    # Stub PushNotificationService
    allow(PushNotificationService).to receive(:send_to_user).and_return(true)
  end

  describe '#perform' do
    it 'sends 24h and 2h reminders' do
      expect_any_instance_of(TeeTimeReminderJob).to receive(:send_24_hour_reminders)
      expect_any_instance_of(TeeTimeReminderJob).to receive(:send_2_hour_reminders)

      TeeTimeReminderJob.perform_now
    end
  end

  describe '24-hour reminders' do
    let!(:tee_time_24h) do
      create(
        :tee_time_posting,
        user: owner,
        golf_course: golf_course,
        tee_time: 24.hours.from_now
      )
    end

    let!(:reservation1) { create(:reservation, user: reserver1, tee_time_posting: tee_time_24h) }
    let!(:reservation2) { create(:reservation, user: reserver2, tee_time_posting: tee_time_24h) }

    it 'sends reminders to owner and all reservers' do
      freeze_time do
        expect(PushNotificationService).to receive(:send_to_user).with(
          owner,
          hash_including(
            title: 'Tee Time Tomorrow',
            notification_type: :reminder_24h
          )
        )

        expect(PushNotificationService).to receive(:send_to_user).with(
          reserver1,
          hash_including(
            title: 'Tee Time Tomorrow',
            notification_type: :reminder_24h
          )
        )

        expect(PushNotificationService).to receive(:send_to_user).with(
          reserver2,
          hash_including(
            title: 'Tee Time Tomorrow',
            notification_type: :reminder_24h
          )
        )

        TeeTimeReminderJob.perform_now
      end
    end

    it 'includes course name and time in body' do
      freeze_time do
        expected_date = tee_time_24h.tee_time.strftime("%b %-d")
        expected_time = tee_time_24h.tee_time.strftime("%-I:%M %p")

        expect(PushNotificationService).to receive(:send_to_user).with(
          owner,
          hash_including(
            body: /Test Course.*#{expected_date}.*#{expected_time}/
          )
        ).at_least(:once)

        TeeTimeReminderJob.perform_now
      end
    end

    it 'respects user reminder preferences' do
      owner.notification_preference.update!(reminder_24h_enabled: false)

      # PushNotificationService is called for all users, but returns false for owner
      expect(PushNotificationService).to receive(:send_to_user).with(owner, anything).and_return(false)
      expect(PushNotificationService).to receive(:send_to_user).with(reserver1, anything).and_return(true)
      expect(PushNotificationService).to receive(:send_to_user).with(reserver2, anything).and_return(true)

      TeeTimeReminderJob.perform_now
    end

    it 'only processes tee times 23-25 hours away' do
      # Create tee times outside the window
      create(:tee_time_posting, user: owner, tee_time: 22.hours.from_now)
      create(:tee_time_posting, user: owner, tee_time: 26.hours.from_now)

      # Should only send to users involved in tee_time_24h
      expect(PushNotificationService).to receive(:send_to_user).exactly(3).times

      TeeTimeReminderJob.perform_now
    end

    it 'sends to owner only once even if they appear multiple times' do
      # Owner also makes a reservation on their own tee time
      create(:reservation, user: owner, tee_time_posting: tee_time_24h)

      # Should still only send once to owner
      expect(PushNotificationService).to receive(:send_to_user).with(owner, anything).once
      expect(PushNotificationService).to receive(:send_to_user).with(reserver1, anything)
      expect(PushNotificationService).to receive(:send_to_user).with(reserver2, anything)

      TeeTimeReminderJob.perform_now
    end
  end

  describe '2-hour reminders' do
    let!(:tee_time_2h) do
      create(
        :tee_time_posting,
        user: owner,
        golf_course: golf_course,
        tee_time: 2.hours.from_now
      )
    end

    let!(:reservation) { create(:reservation, user: reserver1, tee_time_posting: tee_time_2h) }

    it 'sends reminders to owner and reservers' do
      freeze_time do
        expect(PushNotificationService).to receive(:send_to_user).with(
          owner,
          hash_including(
            title: 'Tee Time in 2 Hours',
            notification_type: :reminder_2h
          )
        )

        expect(PushNotificationService).to receive(:send_to_user).with(
          reserver1,
          hash_including(
            title: 'Tee Time in 2 Hours',
            notification_type: :reminder_2h
          )
        )

        TeeTimeReminderJob.perform_now
      end
    end

    it 'respects user reminder preferences' do
      owner.notification_preference.update!(reminder_2h_enabled: false)

      # PushNotificationService is called for all users, but returns false for owner
      expect(PushNotificationService).to receive(:send_to_user).with(owner, anything).and_return(false)
      expect(PushNotificationService).to receive(:send_to_user).with(reserver1, anything).and_return(true)

      TeeTimeReminderJob.perform_now
    end

    it 'only processes tee times 1.5-2.5 hours away' do
      # Create tee times outside the window
      create(:tee_time_posting, user: owner, tee_time: 1.hours.from_now)
      create(:tee_time_posting, user: owner, tee_time: 3.hours.from_now)

      # Should only send to users involved in tee_time_2h
      expect(PushNotificationService).to receive(:send_to_user).exactly(2).times

      TeeTimeReminderJob.perform_now
    end

    it 'respects master reminders_enabled toggle' do
      owner.notification_preference.update!(reminders_enabled: false)

      # PushNotificationService is called for all users, but returns false for owner
      expect(PushNotificationService).to receive(:send_to_user).with(owner, anything).and_return(false)
      expect(PushNotificationService).to receive(:send_to_user).with(reserver1, anything).and_return(true)

      TeeTimeReminderJob.perform_now
    end
  end

  describe 'logging' do
    it 'logs count of 24h reminders sent' do
      create(:tee_time_posting, user: owner, tee_time: 24.hours.from_now)

      allow(Rails.logger).to receive(:info)
      expect(Rails.logger).to receive(:info).with(/Sent 24h reminders for 1 tee times/)

      TeeTimeReminderJob.perform_now
    end

    it 'logs count of 2h reminders sent' do
      create(:tee_time_posting, user: owner, tee_time: 2.hours.from_now)

      allow(Rails.logger).to receive(:info)
      expect(Rails.logger).to receive(:info).with(/Sent 2h reminders for 1 tee times/)

      TeeTimeReminderJob.perform_now
    end
  end
end
