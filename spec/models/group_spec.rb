require 'rails_helper'

RSpec.describe Group, type: :model do
  describe 'associations' do
    it { should belong_to(:owner).class_name('User') }
    it { should have_many(:group_memberships).dependent(:destroy) }
    it { should have_many(:members).through(:group_memberships).source(:user) }
  end

  describe 'validations' do
    subject { build(:group) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:owner) }

    it 'validates uniqueness of name scoped to owner' do
      owner = create(:user)
      create(:group, name: 'Weekend Warriors', owner: owner)
      duplicate_group = build(:group, name: 'Weekend Warriors', owner: owner)

      expect(duplicate_group).not_to be_valid
      expect(duplicate_group.errors[:name]).to include('has already been taken')
    end

    it 'allows same name for different owners' do
      owner1 = create(:user)
      owner2 = create(:user)
      create(:group, name: 'Weekend Warriors', owner: owner1)

      duplicate_name_group = build(:group, name: 'Weekend Warriors', owner: owner2)
      expect(duplicate_name_group).to be_valid
    end
  end

  describe 'attributes' do
    it 'has a name' do
      group = build(:group, name: 'Golf Buddies')
      expect(group.name).to eq('Golf Buddies')
    end

    it 'has an optional description' do
      group = build(:group, description: 'Our regular Saturday group')
      expect(group.description).to eq('Our regular Saturday group')
    end

    it 'can be created without a description' do
      group = build(:group, description: nil)
      expect(group).to be_valid
    end
  end

  describe 'group membership' do
    let(:owner) { create(:user) }
    let(:member) { create(:user) }
    let(:group) { create(:group, owner: owner) }

    it 'can have members added through group_memberships' do
      group.group_memberships.create!(user: member)
      expect(group.members).to include(member)
    end

    it 'owner can be a member of their own group' do
      group.group_memberships.create!(user: owner)
      expect(group.members).to include(owner)
    end

    it 'destroying group destroys group_memberships' do
      group.group_memberships.create!(user: member)
      expect { group.destroy }.to change(GroupMembership, :count).by(-1)
    end
  end
end
