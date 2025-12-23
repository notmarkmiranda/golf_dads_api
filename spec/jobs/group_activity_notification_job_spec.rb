require 'rails_helper'

RSpec.describe GroupActivityNotificationJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  let(:poster) { create(:user, name: 'Poster') }
  let(:member1) { create(:user, name: 'Member 1') }
  let(:member2) { create(:user, name: 'Member 2') }
  let(:group) { create(:group, name: 'Golf Buddies') }
  let(:golf_course) { create(:golf_course, name: 'Test Course') }

  let(:tee_time) do
    create(
      :tee_time_posting,
      user: poster,
      golf_course: golf_course,
      tee_time: 2.days.from_now.change(hour: 10, min: 30),
      groups: [ group ]
    )
  end

  before do
    # Add members to group
    create(:group_membership, user: poster, group: group)
    create(:group_membership, user: member1, group: group)
    create(:group_membership, user: member2, group: group)

    # Create device tokens for members
    create(:device_token, user: member1)
    create(:device_token, user: member2)

    # Stub PushNotificationService methods
    allow(PushNotificationService).to receive(:send_to_user).and_return(true)
    allow(PushNotificationService).to receive(:format_tee_time_for_device).and_call_original
  end

  describe '#perform' do
    it 'sends notification to group members except poster' do
      expect(PushNotificationService).to receive(:send_to_user).exactly(2).times do |user, options|
        expect([member1, member2]).to include(user)
        expect(options[:title]).to eq('Golf Buddies')
        expect(options[:body]).to include('Poster')
        expect(options[:body]).to include('Test Course')
        expect(options[:data]).to eq({
          type: 'group_tee_time',
          tee_time_id: tee_time.id,
          group_id: group.id
        })
        expect(options[:notification_type]).to eq(:group_tee_time)
        true
      end

      GroupActivityNotificationJob.perform_now(tee_time.id)
    end

    it 'excludes users who have muted the group' do
      # Member1 mutes the group
      create(:group_notification_setting, user: member1, group: group, muted: true)

      expect(PushNotificationService).to receive(:send_to_user).once do |user, _options|
        expect(user).to eq(member2)
        true
      end

      GroupActivityNotificationJob.perform_now(tee_time.id)
    end

    it 'uses email prefix if poster has no name' do
      poster.update_columns(name: nil, email_address: 'test@example.com')

      expect(PushNotificationService).to receive(:send_to_user).exactly(2).times do |_user, options|
        expect(options[:body]).to include('test posted')
        true
      end

      GroupActivityNotificationJob.perform_now(tee_time.id)
    end

    it 'handles tee times in multiple groups' do
      group2 = create(:group, name: 'Golf Group 2')
      member3 = create(:user, name: 'Member 3')
      create(:group_membership, user: member3, group: group2)
      create(:device_token, user: member3)

      tee_time.groups << group2

      # Should notify members from both groups (except poster)
      # 2 members from group 1 + 1 member from group 2 = 3 notifications
      expect(PushNotificationService).to receive(:send_to_user).exactly(3).times

      GroupActivityNotificationJob.perform_now(tee_time.id)
    end

    context 'when tee time does not exist' do
      it 'does not raise error' do
        expect {
          GroupActivityNotificationJob.perform_now(999999)
        }.not_to raise_error
      end

      it 'does not send notification' do
        expect(PushNotificationService).not_to receive(:send_to_user)
        GroupActivityNotificationJob.perform_now(999999)
      end
    end

    context 'when tee time has no groups' do
      let(:public_tee_time) { create(:tee_time_posting, user: poster) }

      it 'does not send notification' do
        expect(PushNotificationService).not_to receive(:send_to_user)
        GroupActivityNotificationJob.perform_now(public_tee_time.id)
      end
    end

    context 'with timezone-aware formatting' do
      it 'formats times in each member timezone' do
        # Set up members with different timezones
        member1_token = member1.device_tokens.first
        member2_token = member2.device_tokens.first
        member1_token.update!(timezone: 'America/Denver')     # MST
        member2_token.update!(timezone: 'America/Los_Angeles') # PST

        # Create tee time at 5:15pm UTC
        tee_time.update!(tee_time: Time.utc(2025, 12, 25, 17, 15))

        # Expect different times for each member
        expect(PushNotificationService).to receive(:send_to_user).exactly(2).times do |user, options|
          if user == member1
            # 5:15pm UTC = 10:15am MST
            expect(options[:body]).to include('10:15am')
            expect(options[:body]).not_to include('UTC')
          elsif user == member2
            # 5:15pm UTC = 9:15am PST
            expect(options[:body]).to include('9:15am')
            expect(options[:body]).not_to include('UTC')
          end
          true
        end

        GroupActivityNotificationJob.perform_now(tee_time.id)
      end

      it 'shows UTC suffix for devices without timezone' do
        # Member1 has no timezone set
        member1.device_tokens.first.update!(timezone: nil)
        member2.device_tokens.first.update!(timezone: 'America/Denver')

        tee_time.update!(tee_time: Time.utc(2025, 12, 25, 17, 15))

        expect(PushNotificationService).to receive(:send_to_user).exactly(2).times do |user, options|
          if user == member1
            # No timezone - should show UTC
            expect(options[:body]).to include('5:15pm UTC')
          elsif user == member2
            # Has timezone - should not show UTC
            expect(options[:body]).to include('10:15am')
            expect(options[:body]).not_to include('UTC')
          end
          true
        end

        GroupActivityNotificationJob.perform_now(tee_time.id)
      end
    end
  end
end
