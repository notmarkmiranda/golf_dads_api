require 'rails_helper'

RSpec.describe TeeTimePostingPolicy, type: :policy do
  subject { described_class.new(current_user, record) }

  let(:creator) { create(:user) }
  let(:group_member) { create(:user, email_address: 'member@example.com') }
  let(:non_member) { create(:user, email_address: 'non_member@example.com') }
  let(:admin) { create(:user, email_address: 'admin@example.com', admin: true) }
  let(:group) { create(:group, owner: creator) }

  describe '#index?' do
    let(:record) { TeeTimePosting }

    context 'when user is authenticated' do
      let(:current_user) { group_member }

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
    context 'when posting is public' do
      let(:record) { create(:tee_time_posting, user: creator, group: nil) }

      context 'when user is authenticated' do
        let(:current_user) { non_member }

        it 'allows access' do
          expect(subject).to permit_action(:show)
        end
      end

      context 'when user is a guest' do
        let(:current_user) { nil }

        it 'denies access' do
          expect(subject).not_to permit_action(:show)
        end
      end
    end

    context 'when posting is for a group' do
      let(:record) { create(:tee_time_posting, user: creator, group: group) }

      before do
        create(:group_membership, user: group_member, group: group)
      end

      context 'when user is a group member' do
        let(:current_user) { group_member }

        it 'allows access' do
          expect(subject).to permit_action(:show)
        end
      end

      context 'when user is the posting creator' do
        let(:current_user) { creator }

        it 'allows access' do
          expect(subject).to permit_action(:show)
        end
      end

      context 'when user is not a group member' do
        let(:current_user) { non_member }

        it 'denies access' do
          expect(subject).not_to permit_action(:show)
        end
      end
    end
  end

  describe '#create?' do
    let(:record) { TeeTimePosting.new }

    context 'when user is authenticated' do
      let(:current_user) { group_member }

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
    let(:record) { create(:tee_time_posting, user: creator) }

    context 'when user is the posting creator' do
      let(:current_user) { creator }

      it 'allows access' do
        expect(subject).to permit_action(:update)
      end
    end

    context 'when user is not the creator' do
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
    let(:record) { create(:tee_time_posting, user: creator) }

    context 'when user is the posting creator' do
      let(:current_user) { creator }

      it 'allows access' do
        expect(subject).to permit_action(:destroy)
      end
    end

    context 'when user is not the creator' do
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
    let!(:public_posting) { create(:tee_time_posting, user: creator, group: nil, course_name: 'Public Course') }
    let!(:group_posting) { create(:tee_time_posting, user: creator, group: group, course_name: 'Group Course') }
    let!(:other_group_posting) { create(:tee_time_posting, user: non_member, group: create(:group, owner: non_member), course_name: 'Other Group Course') }
    let!(:own_group_posting) { create(:tee_time_posting, user: group_member, group: group, course_name: 'Own Group Course') }

    before do
      create(:group_membership, user: group_member, group: group)
    end

    context 'when user is authenticated' do
      it 'returns public postings and postings for user groups' do
        scope = Pundit.policy_scope!(group_member, TeeTimePosting)
        expect(scope.to_a).to match_array([public_posting, group_posting, own_group_posting])
        expect(scope.to_a).not_to include(other_group_posting)
      end
    end

    context 'when user is a guest' do
      it 'returns empty scope' do
        scope = Pundit.policy_scope!(nil, TeeTimePosting)
        expect(scope.to_a).to be_empty
      end
    end
  end
end
