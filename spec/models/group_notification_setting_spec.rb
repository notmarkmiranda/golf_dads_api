require 'rails_helper'

RSpec.describe GroupNotificationSetting, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:group) }
  end

  describe 'validations' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }

    it 'validates uniqueness of user_id scoped to group_id' do
      create(:group_notification_setting, user: user, group: group)
      duplicate_setting = build(:group_notification_setting, user: user, group: group)

      expect(duplicate_setting).not_to be_valid
      expect(duplicate_setting.errors[:user_id]).to include('has already been taken')
    end

    it 'allows same user for different groups' do
      group1 = create(:group)
      group2 = create(:group)
      create(:group_notification_setting, user: user, group: group1)

      setting2 = build(:group_notification_setting, user: user, group: group2)
      expect(setting2).to be_valid
    end

    it 'allows different users for same group' do
      user1 = create(:user)
      user2 = create(:user)
      create(:group_notification_setting, user: user1, group: group)

      setting2 = build(:group_notification_setting, user: user2, group: group)
      expect(setting2).to be_valid
    end
  end

  describe 'default values' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }

    it 'defaults muted to false' do
      setting = create(:group_notification_setting, user: user, group: group)
      expect(setting.muted).to be false
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:group1) { create(:group) }
    let(:group2) { create(:group) }

    describe '.muted' do
      it 'returns only muted settings' do
        muted_setting = create(:group_notification_setting, user: user, group: group1, muted: true)
        unmuted_setting = create(:group_notification_setting, user: user, group: group2, muted: false)

        expect(GroupNotificationSetting.muted).to include(muted_setting)
        expect(GroupNotificationSetting.muted).not_to include(unmuted_setting)
      end
    end

    describe '.unmuted' do
      it 'returns only unmuted settings' do
        muted_setting = create(:group_notification_setting, user: user, group: group1, muted: true)
        unmuted_setting = create(:group_notification_setting, user: user, group: group2, muted: false)

        expect(GroupNotificationSetting.unmuted).to include(unmuted_setting)
        expect(GroupNotificationSetting.unmuted).not_to include(muted_setting)
      end
    end
  end
end
