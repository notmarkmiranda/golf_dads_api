require 'rails_helper'

RSpec.describe GroupPolicy, type: :policy do
  subject { described_class.new(current_user, record) }

  let(:owner) { create(:user) }
  let(:member) { create(:user, email_address: 'member@example.com') }
  let(:non_member) { create(:user, email_address: 'non_member@example.com') }
  let(:admin) { create(:user, email_address: 'admin@example.com', admin: true) }

  describe '#index?' do
    let(:record) { Group }

    context 'when user is authenticated' do
      let(:current_user) { member }

      it 'allows access' do
        expect(subject).to permit_action(:index)
      end
    end

    context 'when user is a guest' do
      let(:current_user) { nil }

      it 'denies access' do
        expect(subject).not_to permit_action(:index)
      end
    end
  end

  describe '#show?' do
    let(:record) { create(:group, owner: owner) }

    context 'when user is the group owner' do
      let(:current_user) { owner }

      it 'allows access' do
        expect(subject).to permit_action(:show)
      end
    end

    context 'when user is a group member' do
      let(:current_user) { member }

      before do
        create(:group_membership, user: member, group: record)
      end

      it 'allows access' do
        expect(subject).to permit_action(:show)
      end
    end

    context 'when user is not a member' do
      let(:current_user) { non_member }

      it 'denies access' do
        expect(subject).not_to permit_action(:show)
      end
    end

    context 'when user is a guest' do
      let(:current_user) { nil }

      it 'denies access' do
        expect(subject).not_to permit_action(:show)
      end
    end
  end

  describe '#create?' do
    let(:record) { Group.new }

    context 'when user is authenticated' do
      let(:current_user) { member }

      it 'allows access' do
        expect(subject).to permit_action(:create)
      end
    end

    context 'when user is a guest' do
      let(:current_user) { nil }

      it 'denies access' do
        expect(subject).not_to permit_action(:create)
      end
    end
  end

  describe '#update?' do
    let(:record) { create(:group, owner: owner) }

    context 'when user is the group owner' do
      let(:current_user) { owner }

      it 'allows access' do
        expect(subject).to permit_action(:update)
      end
    end

    context 'when user is a group member but not owner' do
      let(:current_user) { member }

      before do
        create(:group_membership, user: member, group: record)
      end

      it 'denies access' do
        expect(subject).not_to permit_action(:update)
      end
    end

    context 'when user is not a member' do
      let(:current_user) { non_member }

      it 'denies access' do
        expect(subject).not_to permit_action(:update)
      end
    end

    context 'when admin tries to update' do
      let(:current_user) { admin }

      it 'allows access' do
        expect(subject).to permit_action(:update)
      end
    end

    context 'when guest tries to update' do
      let(:current_user) { nil }

      it 'denies access' do
        expect(subject).not_to permit_action(:update)
      end
    end
  end

  describe '#destroy?' do
    let(:record) { create(:group, owner: owner) }

    context 'when user is the group owner' do
      let(:current_user) { owner }

      it 'allows access' do
        expect(subject).to permit_action(:destroy)
      end
    end

    context 'when user is a group member but not owner' do
      let(:current_user) { member }

      before do
        create(:group_membership, user: member, group: record)
      end

      it 'denies access' do
        expect(subject).not_to permit_action(:destroy)
      end
    end

    context 'when user is not a member' do
      let(:current_user) { non_member }

      it 'denies access' do
        expect(subject).not_to permit_action(:destroy)
      end
    end

    context 'when admin tries to destroy' do
      let(:current_user) { admin }

      it 'allows access' do
        expect(subject).to permit_action(:destroy)
      end
    end

    context 'when guest tries to destroy' do
      let(:current_user) { nil }

      it 'denies access' do
        expect(subject).not_to permit_action(:destroy)
      end
    end
  end

  describe 'Scope' do
    let!(:owned_group) { create(:group, owner: owner, name: 'Owned Group') }
    let!(:member_group) { create(:group, owner: member, name: 'Member Group') }
    let!(:other_group) { create(:group, owner: non_member, name: 'Other Group') }

    before do
      # Make owner a member of member_group
      create(:group_membership, user: owner, group: member_group)
    end

    context 'when user is authenticated' do
      it 'returns groups owned by or where user is a member' do
        scope = Pundit.policy_scope!(owner, Group)
        expect(scope.to_a).to match_array([owned_group, member_group])
        expect(scope.to_a).not_to include(other_group)
      end
    end

    context 'when user is a guest' do
      it 'returns empty scope' do
        scope = Pundit.policy_scope!(nil, Group)
        expect(scope.to_a).to be_empty
      end
    end
  end
end
