require 'rails_helper'

RSpec.describe ReservationPolicy, type: :policy do
  subject { described_class.new(current_user, record) }

  let(:reserver) { create(:user) }
  let(:posting_creator) { create(:user, email_address: 'creator@example.com') }
  let(:other_user) { create(:user, email_address: 'other@example.com') }
  let(:admin) { create(:user, email_address: 'admin@example.com', admin: true) }
  let(:posting) { create(:tee_time_posting, user: posting_creator) }

  describe '#index?' do
    let(:record) { Reservation }

    context 'when user is authenticated' do
      let(:current_user) { reserver }

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
    let(:record) { create(:reservation, user: reserver, tee_time_posting: posting) }

    context 'when user is the reserver' do
      let(:current_user) { reserver }

      it 'allows access' do
        expect(subject).to permit_action(:show)
      end
    end

    context 'when user is the posting creator' do
      let(:current_user) { posting_creator }

      it 'allows access' do
        expect(subject).to permit_action(:show)
      end
    end

    context 'when user is neither reserver nor posting creator' do
      let(:current_user) { other_user }

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
    let(:record) { Reservation.new }

    context 'when user is authenticated' do
      let(:current_user) { reserver }

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
    let(:record) { create(:reservation, user: reserver, tee_time_posting: posting) }

    context 'when user is the reserver' do
      let(:current_user) { reserver }

      it 'allows access' do
        expect(subject).to permit_action(:update)
      end
    end

    context 'when user is not the reserver' do
      let(:current_user) { other_user }

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
    let(:record) { create(:reservation, user: reserver, tee_time_posting: posting) }

    context 'when user is the reserver' do
      let(:current_user) { reserver }

      it 'allows access' do
        expect(subject).to permit_action(:destroy)
      end
    end

    context 'when user is the posting creator' do
      let(:current_user) { posting_creator }

      it 'allows access' do
        expect(subject).to permit_action(:destroy)
      end
    end

    context 'when user is neither reserver nor posting creator' do
      let(:current_user) { other_user }

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
    let!(:own_reservation) { create(:reservation, user: reserver, tee_time_posting: posting) }
    let!(:other_posting) { create(:tee_time_posting, user: reserver) }
    let!(:reservation_on_own_posting) { create(:reservation, user: other_user, tee_time_posting: other_posting) }
    let!(:unrelated_reservation) { create(:reservation, user: other_user, tee_time_posting: posting) }

    context 'when user is authenticated' do
      it 'returns user own reservations and reservations on their postings' do
        scope = Pundit.policy_scope!(reserver, Reservation)
        expect(scope.to_a).to match_array([own_reservation, reservation_on_own_posting])
        expect(scope.to_a).not_to include(unrelated_reservation)
      end
    end

    context 'when user is a guest' do
      it 'returns empty scope' do
        scope = Pundit.policy_scope!(nil, Reservation)
        expect(scope.to_a).to be_empty
      end
    end
  end
end
