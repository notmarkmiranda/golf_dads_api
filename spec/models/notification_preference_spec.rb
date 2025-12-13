require 'rails_helper'

RSpec.describe NotificationPreference, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it 'validates uniqueness of user_id' do
      user = create(:user)
      # User already has a notification_preference from callback
      duplicate_preference = build(:notification_preference, user: user)

      expect(duplicate_preference).not_to be_valid
      expect(duplicate_preference.errors[:user_id]).to include('has already been taken')
    end
  end

  describe 'default values' do
    let(:user) { create(:user) }
    let(:preference) { user.notification_preference }

    it 'enables reservations by default' do
      expect(preference.reservations_enabled).to be true
    end

    it 'enables group activity by default' do
      expect(preference.group_activity_enabled).to be true
    end

    it 'enables reminders by default' do
      expect(preference.reminders_enabled).to be true
    end

    it 'enables 24h reminders by default' do
      expect(preference.reminder_24h_enabled).to be true
    end

    it 'enables 2h reminders by default' do
      expect(preference.reminder_2h_enabled).to be true
    end
  end

  describe '#enabled_for?' do
    let(:user) { create(:user) }
    let(:preference) { user.notification_preference }

    context 'with reservation notifications' do
      it 'returns true for reservation_created when reservations_enabled' do
        preference.update!(reservations_enabled: true)
        expect(preference.enabled_for?(:reservation_created)).to be true
      end

      it 'returns false for reservation_created when reservations_enabled is false' do
        preference.update!(reservations_enabled: false)
        expect(preference.enabled_for?(:reservation_created)).to be false
      end

      it 'returns true for reservation_cancelled when reservations_enabled' do
        preference.update!(reservations_enabled: true)
        expect(preference.enabled_for?(:reservation_cancelled)).to be true
      end
    end

    context 'with group activity notifications' do
      it 'returns true for group_tee_time when group_activity_enabled' do
        preference.update!(group_activity_enabled: true)
        expect(preference.enabled_for?(:group_tee_time)).to be true
      end

      it 'returns false for group_tee_time when group_activity_enabled is false' do
        preference.update!(group_activity_enabled: false)
        expect(preference.enabled_for?(:group_tee_time)).to be false
      end
    end

    context 'with reminder notifications' do
      it 'returns true for reminder_24h when both reminders_enabled and reminder_24h_enabled' do
        preference.update!(reminders_enabled: true, reminder_24h_enabled: true)
        expect(preference.enabled_for?(:reminder_24h)).to be true
      end

      it 'returns false for reminder_24h when reminders_enabled is false' do
        preference.update!(reminders_enabled: false, reminder_24h_enabled: true)
        expect(preference.enabled_for?(:reminder_24h)).to be false
      end

      it 'returns false for reminder_24h when reminder_24h_enabled is false' do
        preference.update!(reminders_enabled: true, reminder_24h_enabled: false)
        expect(preference.enabled_for?(:reminder_24h)).to be false
      end

      it 'returns true for reminder_2h when both reminders_enabled and reminder_2h_enabled' do
        preference.update!(reminders_enabled: true, reminder_2h_enabled: true)
        expect(preference.enabled_for?(:reminder_2h)).to be true
      end

      it 'returns false for reminder_2h when reminders_enabled is false' do
        preference.update!(reminders_enabled: false, reminder_2h_enabled: true)
        expect(preference.enabled_for?(:reminder_2h)).to be false
      end
    end

    context 'with unknown notification type' do
      it 'returns false' do
        expect(preference.enabled_for?(:unknown_type)).to be false
      end
    end
  end
end
