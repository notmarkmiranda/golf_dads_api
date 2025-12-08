require 'rails_helper'

RSpec.describe 'Api::TeeTimePostings', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user, email_address: 'other@example.com') }
  let(:token) { user.generate_jwt }
  let(:other_token) { other_user.generate_jwt }
  let(:group) { create(:group, owner: user) }

  describe 'GET /api/v1/tee_time_postings' do
    let!(:public_posting) { create(:tee_time_posting, user: other_user, course_name: 'Public Course') }
    let!(:own_posting) { create(:tee_time_posting, user: user, course_name: 'My Posting') }
    let!(:group_posting) do
      posting = create(:tee_time_posting, user: other_user, course_name: 'Group Posting')
      posting.groups << group
      posting
    end
    let!(:other_group_posting) do
      other_group = create(:group, owner: other_user)
      posting = create(:tee_time_posting, user: other_user, course_name: 'Other Group')
      posting.groups << other_group
      posting
    end

    before do
      create(:group_membership, user: user, group: group)
    end

    context 'when authenticated' do
      it 'returns public postings and postings from user groups' do
        get '/api/v1/tee_time_postings', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['tee_time_postings'].size).to eq(3)

        course_names = json['tee_time_postings'].map { |p| p['course_name'] }
        expect(course_names).to include('Public Course', 'My Posting', 'Group Posting')
        expect(course_names).not_to include('Other Group')
      end

      it 'returns posting details' do
        get '/api/v1/tee_time_postings', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        posting = json['tee_time_postings'].first

        expect(posting).to have_key('id')
        expect(posting).to have_key('user_id')
        expect(posting).to have_key('group_ids')
        expect(posting).to have_key('tee_time')
        expect(posting).to have_key('course_name')
        expect(posting).to have_key('available_spots')
        expect(posting).to have_key('total_spots')
        expect(posting).to have_key('notes')
        expect(posting).to have_key('created_at')
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get '/api/v1/tee_time_postings'

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Unauthorized')
      end
    end
  end

  describe 'GET /api/v1/tee_time_postings/:id' do
    context 'when posting is public' do
      let(:posting) { create(:tee_time_posting, user: other_user) }

      it 'returns the posting' do
        get "/api/v1/tee_time_postings/#{posting.id}", headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['tee_time_posting']['id']).to eq(posting.id)
        expect(json['tee_time_posting']['course_name']).to eq(posting.course_name)
      end
    end

    context 'when posting is for a group' do
      let(:posting) do
        posting = create(:tee_time_posting, user: other_user)
        posting.groups << group
        posting
      end

      before do
        create(:group_membership, user: user, group: group)
      end

      it 'returns the posting for group members' do
        get "/api/v1/tee_time_postings/#{posting.id}", headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['tee_time_posting']['id']).to eq(posting.id)
      end
    end

    context 'when user is the creator' do
      let(:posting) { create(:tee_time_posting, user: user) }

      it 'returns the posting' do
        get "/api/v1/tee_time_postings/#{posting.id}", headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['tee_time_posting']['id']).to eq(posting.id)
      end
    end

    context 'when user is not authorized' do
      let(:other_group) { create(:group, owner: other_user) }
      let(:posting) do
        posting = create(:tee_time_posting, user: other_user)
        posting.groups << other_group
        posting
      end

      it 'returns forbidden' do
        get "/api/v1/tee_time_postings/#{posting.id}", headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('You are not authorized to perform this action')
      end
    end

    context 'when posting does not exist' do
      it 'returns not found' do
        get '/api/v1/tee_time_postings/99999', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Tee time posting not found')
      end
    end

    context 'when not authenticated' do
      let(:posting) { create(:tee_time_posting, user: user) }

      it 'returns unauthorized' do
        get "/api/v1/tee_time_postings/#{posting.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/tee_time_postings' do
    context 'with valid parameters' do
      let(:future_time) { 2.days.from_now }
      let(:valid_params) do
        {
          tee_time_posting: {
            tee_time: future_time,
            course_name: 'Pebble Beach',
            total_spots: 4,
            notes: 'Looking for players'
          },
          initial_reservation_spots: 2
        }
      end

      it 'creates a public posting' do
        expect {
          post '/api/v1/tee_time_postings', params: valid_params, headers: { 'Authorization' => "Bearer #{token}" }
        }.to change(TeeTimePosting, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['tee_time_posting']['course_name']).to eq('Pebble Beach')
        expect(json['tee_time_posting']['total_spots']).to eq(4)
        expect(json['tee_time_posting']['available_spots']).to eq(2)
        expect(json['tee_time_posting']['group_ids']).to eq([])
        expect(json['tee_time_posting']['user_id']).to eq(user.id)
      end

      it 'creates a group posting' do
        params = valid_params.deep_merge(tee_time_posting: { group_ids: [group.id] })

        post '/api/v1/tee_time_postings', params: params, headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['tee_time_posting']['group_ids']).to eq([group.id])
      end

      it 'creates posting without optional fields' do
        minimal_params = {
          tee_time_posting: {
            tee_time: future_time,
            course_name: 'Simple Course',
            total_spots: 1
          }
        }

        post '/api/v1/tee_time_postings', params: minimal_params, headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['tee_time_posting']['total_spots']).to eq(1)
        expect(json['tee_time_posting']['available_spots']).to eq(1)
        expect(json['tee_time_posting']['notes']).to be_nil
      end
    end

    context 'with invalid parameters' do
      let(:future_time) { 2.days.from_now }

      it 'returns error when course_name is missing' do
        post '/api/v1/tee_time_postings',
             params: { tee_time_posting: { tee_time: future_time, total_spots: 2 } },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']).to have_key('base')
        expect(json['errors']['base']).to include('Must specify either course name or golf course')
      end

      it 'returns error when tee_time is missing' do
        post '/api/v1/tee_time_postings',
             params: { tee_time_posting: { course_name: 'Course', total_spots: 2 } },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']).to have_key('tee_time')
      end

      it 'returns error when total_spots is zero' do
        post '/api/v1/tee_time_postings',
             params: { tee_time_posting: { tee_time: future_time, course_name: 'Course', total_spots: 0 } },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']).to have_key('total_spots')
      end

      it 'returns error when tee_time is in the past' do
        post '/api/v1/tee_time_postings',
             params: { tee_time_posting: { tee_time: 1.day.ago, course_name: 'Course', total_spots: 2 } },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']).to have_key('tee_time')
      end

      it 'returns error when initial_reservation_spots exceeds total_spots' do
        post '/api/v1/tee_time_postings',
             params: { tee_time_posting: { tee_time: future_time, course_name: 'Course', total_spots: 2 }, initial_reservation_spots: 4 },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']).to have_key('spots_reserved')
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        post '/api/v1/tee_time_postings',
             params: { tee_time_posting: { tee_time: 1.day.from_now, course_name: 'Course', available_spots: 2 } }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/tee_time_postings/:id' do
    let(:posting) { create(:tee_time_posting, user: user, course_name: 'Original Course', total_spots: 2) }

    context 'when user is the creator' do
      it 'updates the posting' do
        patch "/api/v1/tee_time_postings/#{posting.id}",
              params: { tee_time_posting: { course_name: 'Updated Course', total_spots: 3 } },
              headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['tee_time_posting']['course_name']).to eq('Updated Course')
        expect(json['tee_time_posting']['total_spots']).to eq(3)

        posting.reload
        expect(posting.course_name).to eq('Updated Course')
        expect(posting.total_spots).to eq(3)
      end

      it 'updates only provided fields' do
        patch "/api/v1/tee_time_postings/#{posting.id}",
              params: { tee_time_posting: { notes: 'New notes' } },
              headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['tee_time_posting']['notes']).to eq('New notes')
        expect(json['tee_time_posting']['course_name']).to eq('Original Course')
      end
    end

    context 'with invalid parameters' do
      it 'returns error when total_spots is invalid' do
        patch "/api/v1/tee_time_postings/#{posting.id}",
              params: { tee_time_posting: { total_spots: 0 } },
              headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']).to have_key('total_spots')
      end
    end

    context 'when user is not the creator' do
      it 'returns forbidden' do
        patch "/api/v1/tee_time_postings/#{posting.id}",
              params: { tee_time_posting: { course_name: 'Hacked' } },
              headers: { 'Authorization' => "Bearer #{other_token}" }

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('You are not authorized to perform this action')
      end
    end

    context 'when posting does not exist' do
      it 'returns not found' do
        patch '/api/v1/tee_time_postings/99999',
              params: { tee_time_posting: { course_name: 'New' } },
              headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        patch "/api/v1/tee_time_postings/#{posting.id}",
              params: { tee_time_posting: { course_name: 'New' } }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/tee_time_postings/:id' do
    let!(:posting) { create(:tee_time_posting, user: user) }

    context 'when user is the creator' do
      it 'deletes the posting' do
        expect {
          delete "/api/v1/tee_time_postings/#{posting.id}", headers: { 'Authorization' => "Bearer #{token}" }
        }.to change(TeeTimePosting, :count).by(-1)

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when user is not the creator' do
      it 'returns forbidden' do
        expect {
          delete "/api/v1/tee_time_postings/#{posting.id}", headers: { 'Authorization' => "Bearer #{other_token}" }
        }.not_to change(TeeTimePosting, :count)

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('You are not authorized to perform this action')
      end
    end

    context 'when posting does not exist' do
      it 'returns not found' do
        delete '/api/v1/tee_time_postings/99999', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        delete "/api/v1/tee_time_postings/#{posting.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
