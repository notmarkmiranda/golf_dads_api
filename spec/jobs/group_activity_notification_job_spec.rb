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

    # Stub PushNotificationService
    allow(PushNotificationService).to receive(:send_to_users).and_return(
      { success_count: 2, failure_count: 0 }
    )
  end

  describe '#perform' do
    it 'sends notification to group members except poster' do
      freeze_time do
        expected_date = tee_time.tee_time.strftime("%b %-d")
        expected_time = tee_time.tee_time.strftime("%-I:%M %p")

        expect(PushNotificationService).to receive(:send_to_users) do |users, options|
          expect(users).to contain_exactly(member1, member2)
          expect(options[:title]).to eq('Golf Buddies')
          expect(options[:body]).to include('Poster')
          expect(options[:body]).to include('Test Course')
          expect(options[:body]).to include(expected_date)
          expect(options[:body]).to include(expected_time)
          expect(options[:data]).to eq({
            type: 'group_tee_time',
            tee_time_id: tee_time.id,
            group_id: group.id
          })
          expect(options[:notification_type]).to eq(:group_tee_time)

          { success_count: 2, failure_count: 0 }
        end

        GroupActivityNotificationJob.perform_now(tee_time.id)
      end
    end

    it 'excludes users who have muted the group' do
      # Member1 mutes the group
      create(:group_notification_setting, user: member1, group: group, muted: true)

      expect(PushNotificationService).to receive(:send_to_users) do |users, _options|
        expect(users).to contain_exactly(member2)
        { success_count: 1, failure_count: 0 }
      end

      GroupActivityNotificationJob.perform_now(tee_time.id)
    end

    it 'uses email prefix if poster has no name' do
      poster.update_columns(name: nil, email_address: 'test@example.com')

      expect(PushNotificationService).to receive(:send_to_users) do |_users, options|
        expect(options[:body]).to include('test posted')
        { success_count: 2, failure_count: 0 }
      end

      GroupActivityNotificationJob.perform_now(tee_time.id)
    end

    it 'handles tee times in multiple groups' do
      group2 = create(:group, name: 'Golf Group 2')
      member3 = create(:user, name: 'Member 3')
      create(:group_membership, user: member3, group: group2)

      tee_time.groups << group2

      # Should notify members from both groups (except poster)
      expect(PushNotificationService).to receive(:send_to_users).twice

      GroupActivityNotificationJob.perform_now(tee_time.id)
    end

    context 'when tee time does not exist' do
      it 'does not raise error' do
        expect {
          GroupActivityNotificationJob.perform_now(999999)
        }.not_to raise_error
      end

      it 'does not send notification' do
        expect(PushNotificationService).not_to receive(:send_to_users)
        GroupActivityNotificationJob.perform_now(999999)
      end
    end

    context 'when tee time has no groups' do
      let(:public_tee_time) { create(:tee_time_posting, user: poster) }

      it 'does not send notification' do
        expect(PushNotificationService).not_to receive(:send_to_users)
        GroupActivityNotificationJob.perform_now(public_tee_time.id)
      end
    end
  end
end
