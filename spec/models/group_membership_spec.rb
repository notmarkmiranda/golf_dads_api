require 'rails_helper'

RSpec.describe GroupMembership, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:group) }
  end

  describe 'validations' do
    subject { build(:group_membership) }

    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:group) }

    it 'validates uniqueness of user_id scoped to group_id' do
      user = create(:user)
      group = create(:group)
      create(:group_membership, user: user, group: group)

      duplicate_membership = build(:group_membership, user: user, group: group)
      expect(duplicate_membership).not_to be_valid
      expect(duplicate_membership.errors[:user_id]).to include('has already been taken')
    end

    it 'allows same user to join different groups' do
      user = create(:user)
      group1 = create(:group)
      group2 = create(:group)

      create(:group_membership, user: user, group: group1)
      second_membership = build(:group_membership, user: user, group: group2)

      expect(second_membership).to be_valid
    end

    it 'allows different users to join same group' do
      user1 = create(:user)
      user2 = create(:user)
      group = create(:group)

      create(:group_membership, user: user1, group: group)
      second_membership = build(:group_membership, user: user2, group: group)

      expect(second_membership).to be_valid
    end
  end

  describe 'membership creation' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }

    it 'can be created with user and group' do
      membership = GroupMembership.create(user: user, group: group)
      expect(membership).to be_persisted
      expect(membership.user).to eq(user)
      expect(membership.group).to eq(group)
    end

    it 'adds user to group members through association' do
      membership = GroupMembership.create!(user: user, group: group)
      expect(group.members).to include(user)
    end
  end

  describe 'membership destruction' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let!(:membership) { create(:group_membership, user: user, group: group) }

    it 'removes user from group members when destroyed' do
      expect(group.members).to include(user)
      membership.destroy
      expect(group.reload.members).not_to include(user)
    end

    it 'is destroyed when user is destroyed' do
      expect { user.destroy }.to change(GroupMembership, :count).by(-1)
    end

    it 'is destroyed when group is destroyed' do
      expect { group.destroy }.to change(GroupMembership, :count).by(-1)
    end
  end
end
