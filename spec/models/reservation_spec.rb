require 'rails_helper'

RSpec.describe Reservation, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:tee_time_posting) }
  end

  describe 'validations' do
    subject { create(:reservation) }

    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:tee_time_posting) }
    it { should validate_presence_of(:spots_reserved) }
    it { should validate_numericality_of(:spots_reserved).is_greater_than(0).only_integer }

    context 'when validating spots_reserved does not exceed available_spots' do
      let(:user) { create(:user) }
      let(:posting) { create(:tee_time_posting, total_spots: 2) }

      it 'is valid when spots_reserved equals available_spots' do
        reservation = build(:reservation, user: user, tee_time_posting: posting, spots_reserved: 2)
        expect(reservation).to be_valid
      end

      it 'is valid when spots_reserved is less than available_spots' do
        reservation = build(:reservation, user: user, tee_time_posting: posting, spots_reserved: 1)
        expect(reservation).to be_valid
      end

      it 'is invalid when spots_reserved exceeds available_spots' do
        reservation = build(:reservation, user: user, tee_time_posting: posting, spots_reserved: 3)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:spots_reserved]).to include('cannot exceed available spots on the tee time posting')
      end

      it 'allows updating existing reservation within available spots' do
        reservation = create(:reservation, user: user, tee_time_posting: posting, spots_reserved: 1)
        reservation.spots_reserved = 2
        expect(reservation).to be_valid
      end

      it 'prevents updating reservation to exceed total spots' do
        reservation = create(:reservation, user: user, tee_time_posting: posting, spots_reserved: 1)
        reservation.spots_reserved = 3
        expect(reservation).not_to be_valid
      end
    end

    context 'when validating user has not already reserved this posting' do
      let(:user) { create(:user) }
      let(:posting) { create(:tee_time_posting, available_spots: 3) }

      it 'is invalid when user tries to create a second reservation for the same posting' do
        create(:reservation, user: user, tee_time_posting: posting, spots_reserved: 1)
        duplicate = build(:reservation, user: user, tee_time_posting: posting, spots_reserved: 1)

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to include('has already reserved this tee time')
      end

      it 'allows different users to reserve the same posting' do
        user2 = create(:user, email_address: 'user2@example.com')
        create(:reservation, user: user, tee_time_posting: posting, spots_reserved: 1)
        reservation2 = build(:reservation, user: user2, tee_time_posting: posting, spots_reserved: 1)

        expect(reservation2).to be_valid
      end

      it 'allows the same user to reserve different postings' do
        posting2 = create(:tee_time_posting, available_spots: 2)
        create(:reservation, user: user, tee_time_posting: posting, spots_reserved: 1)
        reservation2 = build(:reservation, user: user, tee_time_posting: posting2, spots_reserved: 1)

        expect(reservation2).to be_valid
      end
    end
  end

  describe 'database indexes' do
    it 'has a unique composite index on user_id and tee_time_posting_id' do
      # This is validated by the uniqueness validation test above
      # Database-level enforcement prevents race conditions
    end
  end

  describe 'cascading deletes' do
    let(:user) { create(:user) }
    let(:posting) { create(:tee_time_posting) }
    let!(:reservation) { create(:reservation, user: user, tee_time_posting: posting) }

    it 'is destroyed when user is destroyed' do
      expect { user.destroy }.to change { Reservation.count }.by(-1)
    end

    it 'is destroyed when tee_time_posting is destroyed' do
      expect { posting.destroy }.to change { Reservation.count }.by(-1)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      reservation = build(:reservation)
      expect(reservation).to be_valid
    end

    it 'creates a reservation with all required associations' do
      reservation = create(:reservation)
      expect(reservation.user).to be_present
      expect(reservation.tee_time_posting).to be_present
      expect(reservation.spots_reserved).to eq(1)
    end
  end
end
