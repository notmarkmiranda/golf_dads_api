require 'rails_helper'

RSpec.describe 'Api::Reservations', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user, email_address: 'other@example.com') }
  let(:posting_creator) { create(:user, email_address: 'creator@example.com') }
  let(:token) { user.generate_jwt }
  let(:other_token) { other_user.generate_jwt }
  let(:creator_token) { posting_creator.generate_jwt }

  describe 'GET /api/v1/reservations' do
    let!(:own_reservation) { create(:reservation, user: user, tee_time_posting: create(:tee_time_posting, user: posting_creator)) }
    let!(:posting_by_user) { create(:tee_time_posting, user: user) }
    let!(:reservation_on_own_posting) { create(:reservation, user: other_user, tee_time_posting: posting_by_user) }
    let!(:other_reservation) { create(:reservation, user: other_user, tee_time_posting: create(:tee_time_posting, user: posting_creator)) }

    context 'when authenticated' do
      it 'returns user own reservations and reservations on their postings' do
        get '/api/v1/reservations', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['reservations'].size).to eq(2)

        reservation_ids = json['reservations'].map { |r| r['id'] }
        expect(reservation_ids).to include(own_reservation.id, reservation_on_own_posting.id)
        expect(reservation_ids).not_to include(other_reservation.id)
      end

      it 'returns reservation details' do
        get '/api/v1/reservations', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        reservation = json['reservations'].first

        expect(reservation).to have_key('id')
        expect(reservation).to have_key('user_id')
        expect(reservation).to have_key('tee_time_posting_id')
        expect(reservation).to have_key('spots_reserved')
        expect(reservation).to have_key('created_at')
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get '/api/v1/reservations'

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Unauthorized')
      end
    end
  end

  describe 'GET /api/v1/reservations/:id' do
    let(:posting) { create(:tee_time_posting, user: posting_creator) }
    let(:reservation) { create(:reservation, user: user, tee_time_posting: posting) }

    context 'when user is the reserver' do
      it 'returns the reservation' do
        get "/api/v1/reservations/#{reservation.id}", headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['reservation']['id']).to eq(reservation.id)
        expect(json['reservation']['user_id']).to eq(user.id)
        expect(json['reservation']['spots_reserved']).to eq(reservation.spots_reserved)
      end
    end

    context 'when user is the posting creator' do
      it 'returns the reservation' do
        get "/api/v1/reservations/#{reservation.id}", headers: { 'Authorization' => "Bearer #{creator_token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['reservation']['id']).to eq(reservation.id)
      end
    end

    context 'when user is neither reserver nor posting creator' do
      it 'returns forbidden' do
        get "/api/v1/reservations/#{reservation.id}", headers: { 'Authorization' => "Bearer #{other_token}" }

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('You are not authorized to perform this action')
      end
    end

    context 'when reservation does not exist' do
      it 'returns not found' do
        get '/api/v1/reservations/99999', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Reservation not found')
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get "/api/v1/reservations/#{reservation.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/reservations' do
    let(:posting) { create(:tee_time_posting, user: posting_creator, available_spots: 3) }

    context 'with valid parameters' do
      let(:valid_params) do
        {
          reservation: {
            tee_time_posting_id: posting.id,
            spots_reserved: 2
          }
        }
      end

      it 'creates a new reservation' do
        expect {
          post '/api/v1/reservations', params: valid_params, headers: { 'Authorization' => "Bearer #{token}" }
        }.to change(Reservation, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['reservation']['user_id']).to eq(user.id)
        expect(json['reservation']['tee_time_posting_id']).to eq(posting.id)
        expect(json['reservation']['spots_reserved']).to eq(2)
      end

      it 'creates reservation with 1 spot' do
        post '/api/v1/reservations',
             params: { reservation: { tee_time_posting_id: posting.id, spots_reserved: 1 } },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['reservation']['spots_reserved']).to eq(1)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when tee_time_posting_id is missing' do
        post '/api/v1/reservations',
             params: { reservation: { spots_reserved: 2 } },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to have_key('tee_time_posting')
      end

      it 'returns error when spots_reserved is missing' do
        post '/api/v1/reservations',
             params: { reservation: { tee_time_posting_id: posting.id } },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to have_key('spots_reserved')
      end

      it 'returns error when spots_reserved is zero' do
        post '/api/v1/reservations',
             params: { reservation: { tee_time_posting_id: posting.id, spots_reserved: 0 } },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to have_key('spots_reserved')
      end

      it 'returns error when spots_reserved exceeds available spots' do
        post '/api/v1/reservations',
             params: { reservation: { tee_time_posting_id: posting.id, spots_reserved: 5 } },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to have_key('spots_reserved')
      end

      it 'returns error when user already has a reservation for this posting' do
        create(:reservation, user: user, tee_time_posting: posting, spots_reserved: 1)

        post '/api/v1/reservations',
             params: { reservation: { tee_time_posting_id: posting.id, spots_reserved: 1 } },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to have_key('user_id')
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        post '/api/v1/reservations',
             params: { reservation: { tee_time_posting_id: posting.id, spots_reserved: 2 } }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/reservations/:id' do
    let(:posting) { create(:tee_time_posting, user: posting_creator, available_spots: 5, total_spots: 5) }
    let(:reservation) { create(:reservation, user: user, tee_time_posting: posting, spots_reserved: 2) }

    context 'when user is the reserver' do
      it 'updates the reservation' do
        patch "/api/v1/reservations/#{reservation.id}",
              params: { reservation: { spots_reserved: 3 } },
              headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['reservation']['spots_reserved']).to eq(3)

        reservation.reload
        expect(reservation.spots_reserved).to eq(3)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when spots_reserved is invalid' do
        patch "/api/v1/reservations/#{reservation.id}",
              params: { reservation: { spots_reserved: 0 } },
              headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to have_key('spots_reserved')
      end

      it 'returns error when spots_reserved exceeds available spots' do
        patch "/api/v1/reservations/#{reservation.id}",
              params: { reservation: { spots_reserved: 10 } },
              headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to have_key('spots_reserved')
      end
    end

    context 'when user is not the reserver' do
      it 'returns forbidden' do
        patch "/api/v1/reservations/#{reservation.id}",
              params: { reservation: { spots_reserved: 3 } },
              headers: { 'Authorization' => "Bearer #{other_token}" }

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('You are not authorized to perform this action')
      end
    end

    context 'when reservation does not exist' do
      it 'returns not found' do
        patch '/api/v1/reservations/99999',
              params: { reservation: { spots_reserved: 3 } },
              headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        patch "/api/v1/reservations/#{reservation.id}",
              params: { reservation: { spots_reserved: 3 } }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/reservations/:id' do
    let(:posting) { create(:tee_time_posting, user: posting_creator) }
    let!(:reservation) { create(:reservation, user: user, tee_time_posting: posting) }

    context 'when user is the reserver' do
      it 'deletes the reservation' do
        expect {
          delete "/api/v1/reservations/#{reservation.id}", headers: { 'Authorization' => "Bearer #{token}" }
        }.to change(Reservation, :count).by(-1)

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when user is the posting creator' do
      it 'deletes the reservation (can cancel reservations on their posting)' do
        expect {
          delete "/api/v1/reservations/#{reservation.id}", headers: { 'Authorization' => "Bearer #{creator_token}" }
        }.to change(Reservation, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when user is neither reserver nor posting creator' do
      it 'returns forbidden' do
        expect {
          delete "/api/v1/reservations/#{reservation.id}", headers: { 'Authorization' => "Bearer #{other_token}" }
        }.not_to change(Reservation, :count)

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('You are not authorized to perform this action')
      end
    end

    context 'when reservation does not exist' do
      it 'returns not found' do
        delete '/api/v1/reservations/99999', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        delete "/api/v1/reservations/#{reservation.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
