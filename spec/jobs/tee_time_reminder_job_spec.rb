require 'rails_helper'

RSpec.describe TeeTimeReminderJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  let(:owner) { create(:user, name: 'Owner') }
  let(:reserver1) { create(:user, name: 'Reserver 1') }
  let(:reserver2) { create(:user, name: 'Reserver 2') }
  let(:golf_course) { create(:golf_course, name: 'Test Course') }

  before do
    # Create device tokens for users
    create(:device_token, user: owner)
    create(:device_token, user: reserver1)
    create(:device_token, user: reserver2)

    # Stub PushNotificationService
    allow(PushNotificationService).to receive(:send_to_user).and_return(true)
    allow(PushNotificationService).to receive(:format_tee_time_for_device).and_call_original
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

    it 'includes course name and formatted time in body' do
      expect(PushNotificationService).to receive(:send_to_user).at_least(:once) do |user, options|
        expect(options[:body]).to include('Test Course')
        expect(options[:body]).to match(/on \w+ \d+ at \d+:\d+(am|pm)/)
        true
      end

      TeeTimeReminderJob.perform_now
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

  describe 'timezone-aware formatting' do
    let(:future_tee_time) { 25.hours.from_now } # Ensure it's in the future
    let!(:tee_time_tz) do
      create(
        :tee_time_posting,
        user: owner,
        golf_course: golf_course,
        tee_time: future_tee_time
      )
    end

    before do
      # Set current time to be 24 hours before tee time for the job to pick it up
      travel_to future_tee_time - 24.hours
    end

    after do
      travel_back
    end

    it 'formats times in each user timezone' do
      # Set up users with different timezones
      owner_token = owner.device_tokens.first
      reserver1_token = reserver1.device_tokens.first
      owner_token.update!(timezone: 'America/Denver')     # MST (UTC-7)
      reserver1_token.update!(timezone: 'America/Los_Angeles') # PST (UTC-8)

      create(:reservation, user: reserver1, tee_time_posting: tee_time_tz)

      # Calculate expected times in each timezone
      denver_time = future_tee_time.in_time_zone('America/Denver')
      la_time = future_tee_time.in_time_zone('America/Los_Angeles')

      # Expect different times for each user
      expect(PushNotificationService).to receive(:send_to_user).exactly(2).times do |user, options|
        if user == owner
          expect(options[:body]).to include(denver_time.strftime('%-I:%M%p').downcase)
          expect(options[:body]).not_to include('UTC')
        elsif user == reserver1
          expect(options[:body]).to include(la_time.strftime('%-I:%M%p').downcase)
          expect(options[:body]).not_to include('UTC')
        end
        true
      end

      TeeTimeReminderJob.perform_now
    end

    it 'shows UTC suffix for devices without timezone' do
      # Owner has no timezone set
      owner_token = owner.device_tokens.first
      reserver1_token = reserver1.device_tokens.first
      owner_token.update!(timezone: nil)
      reserver1_token.update!(timezone: 'America/Denver')

      create(:reservation, user: reserver1, tee_time_posting: tee_time_tz)

      # Calculate expected times
      utc_time = future_tee_time.utc
      denver_time = future_tee_time.in_time_zone('America/Denver')

      expect(PushNotificationService).to receive(:send_to_user).exactly(2).times do |user, options|
        if user == owner
          # No timezone - should show UTC
          expect(options[:body]).to include(utc_time.strftime('%-I:%M%p').downcase + ' UTC')
        elsif user == reserver1
          # Has timezone - should not show UTC
          expect(options[:body]).to include(denver_time.strftime('%-I:%M%p').downcase)
          expect(options[:body]).not_to include('UTC')
        end
        true
      end

      TeeTimeReminderJob.perform_now
    end
  end
end
