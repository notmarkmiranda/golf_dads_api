require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject { described_class.new(current_user, record) }

  let(:user) { create(:user) }
  let(:other_user) { create(:user, email_address: 'other@example.com') }
  let(:admin) { create(:user, email_address: 'admin@example.com', admin: true) }

  describe '#index?' do
    let(:record) { User }

    context 'when user is authenticated' do
      let(:current_user) { user }

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
    context 'when user views their own profile' do
      let(:current_user) { user }
      let(:record) { user }

      it 'allows access' do
        expect(subject).to permit_action(:show)
      end
    end

    context 'when user views another users profile' do
      let(:current_user) { user }
      let(:record) { other_user }

      it 'allows access' do
        expect(subject).to permit_action(:show)
      end
    end

    context 'when user is a guest' do
      let(:current_user) { nil }
      let(:record) { user }

      it 'denies access' do
        expect(subject).not_to permit_action(:show)
      end
    end
  end

  describe '#create?' do
    let(:record) { User.new }

    context 'when anyone tries to create a user' do
      let(:current_user) { nil }

      it 'allows access (for signup)' do
        expect(subject).to permit_action(:create)
      end
    end
  end

  describe '#update?' do
    context 'when user updates their own profile' do
      let(:current_user) { user }
      let(:record) { user }

      it 'allows access' do
        expect(subject).to permit_action(:update)
      end
    end

    context 'when user tries to update another user' do
      let(:current_user) { user }
      let(:record) { other_user }

      it 'denies access' do
        expect(subject).not_to permit_action(:update)
      end
    end

    context 'when admin updates any user' do
      let(:current_user) { admin }
      let(:record) { other_user }

      it 'allows access' do
        expect(subject).to permit_action(:update)
      end
    end

    context 'when guest tries to update' do
      let(:current_user) { nil }
      let(:record) { user }

      it 'denies access' do
        expect(subject).not_to permit_action(:update)
      end
    end
  end

  describe '#destroy?' do
    context 'when user deletes their own account' do
      let(:current_user) { user }
      let(:record) { user }

      it 'allows access' do
        expect(subject).to permit_action(:destroy)
      end
    end

    context 'when user tries to delete another user' do
      let(:current_user) { user }
      let(:record) { other_user }

      it 'denies access' do
        expect(subject).not_to permit_action(:destroy)
      end
    end

    context 'when admin deletes any user' do
      let(:current_user) { admin }
      let(:record) { other_user }

      it 'allows access' do
        expect(subject).to permit_action(:destroy)
      end
    end

    context 'when guest tries to delete' do
      let(:current_user) { nil }
      let(:record) { user }

      it 'denies access' do
        expect(subject).not_to permit_action(:destroy)
      end
    end
  end

  describe 'Scope' do
    let!(:users) { create_list(:user, 3) }

    context 'when user is authenticated' do
      it 'returns all users' do
        scope = Pundit.policy_scope!(user, User)
        expect(scope.to_a).to match_array(User.all.to_a)
      end
    end

    context 'when user is a guest' do
      it 'returns empty scope' do
        scope = Pundit.policy_scope!(nil, User)
        expect(scope.to_a).to be_empty
      end
    end
  end
end
