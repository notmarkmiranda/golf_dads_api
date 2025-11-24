require 'rails_helper'

RSpec.describe 'Api::Groups', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user, email_address: 'other@example.com') }
  let(:token) { user.generate_jwt }
  let(:other_token) { other_user.generate_jwt }

  describe 'GET /api/v1/groups' do
    let!(:owned_group) { create(:group, owner: user, name: 'My Group') }
    let!(:member_group) { create(:group, owner: other_user, name: 'Member Group') }
    let!(:other_group) { create(:group, owner: other_user, name: 'Other Group') }

    before do
      create(:group_membership, user: user, group: member_group)
    end

    context 'when authenticated' do
      it 'returns groups user owns or is a member of' do
        get '/api/v1/groups', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['groups'].size).to eq(2)

        group_names = json['groups'].map { |g| g['name'] }
        expect(group_names).to include('My Group', 'Member Group')
        expect(group_names).not_to include('Other Group')
      end

      it 'returns group details' do
        get '/api/v1/groups', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        group = json['groups'].first

        expect(group).to have_key('id')
        expect(group).to have_key('name')
        expect(group).to have_key('description')
        expect(group).to have_key('owner_id')
        expect(group).to have_key('created_at')
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get '/api/v1/groups'

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Unauthorized')
      end
    end
  end

  describe 'GET /api/v1/groups/:id' do
    let(:group) { create(:group, owner: user, name: 'Test Group', description: 'Test Description') }

    context 'when user is the owner' do
      it 'returns the group' do
        get "/api/v1/groups/#{group.id}", headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['group']['id']).to eq(group.id)
        expect(json['group']['name']).to eq('Test Group')
        expect(json['group']['description']).to eq('Test Description')
        expect(json['group']['owner_id']).to eq(user.id)
      end
    end

    context 'when user is a member' do
      let(:group) { create(:group, owner: other_user) }

      before do
        create(:group_membership, user: user, group: group)
      end

      it 'returns the group' do
        get "/api/v1/groups/#{group.id}", headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['group']['id']).to eq(group.id)
      end
    end

    context 'when user is not authorized' do
      let(:group) { create(:group, owner: other_user) }

      it 'returns forbidden' do
        get "/api/v1/groups/#{group.id}", headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('You are not authorized to perform this action')
      end
    end

    context 'when group does not exist' do
      it 'returns not found' do
        get '/api/v1/groups/99999', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Group not found')
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get "/api/v1/groups/#{group.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/groups' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          group: {
            name: 'New Group',
            description: 'A new golf group'
          }
        }
      end

      it 'creates a new group' do
        expect {
          post '/api/v1/groups', params: valid_params, headers: { 'Authorization' => "Bearer #{token}" }
        }.to change(Group, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['group']['name']).to eq('New Group')
        expect(json['group']['description']).to eq('A new golf group')
        expect(json['group']['owner_id']).to eq(user.id)
      end

      it 'creates group without description' do
        post '/api/v1/groups',
             params: { group: { name: 'Simple Group' } },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['group']['name']).to eq('Simple Group')
        expect(json['group']['description']).to be_nil
      end
    end

    context 'with invalid parameters' do
      it 'returns error when name is missing' do
        post '/api/v1/groups',
             params: { group: { description: 'No name' } },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']).to have_key('name')
      end

      it 'returns error when name is duplicate for same owner' do
        create(:group, owner: user, name: 'Duplicate Group')

        post '/api/v1/groups',
             params: { group: { name: 'Duplicate Group' } },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']).to have_key('name')
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        post '/api/v1/groups', params: { group: { name: 'New Group' } }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/groups/:id' do
    let(:group) { create(:group, owner: user, name: 'Original Name', description: 'Original Description') }

    context 'when user is the owner' do
      it 'updates the group' do
        patch "/api/v1/groups/#{group.id}",
              params: { group: { name: 'Updated Name', description: 'Updated Description' } },
              headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['group']['name']).to eq('Updated Name')
        expect(json['group']['description']).to eq('Updated Description')

        group.reload
        expect(group.name).to eq('Updated Name')
        expect(group.description).to eq('Updated Description')
      end

      it 'updates only provided fields' do
        patch "/api/v1/groups/#{group.id}",
              params: { group: { name: 'New Name Only' } },
              headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['group']['name']).to eq('New Name Only')
        expect(json['group']['description']).to eq('Original Description')
      end
    end

    context 'with invalid parameters' do
      it 'returns error when name is blank' do
        patch "/api/v1/groups/#{group.id}",
              params: { group: { name: '' } },
              headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']).to have_key('name')
      end
    end

    context 'when user is not the owner' do
      it 'returns forbidden' do
        patch "/api/v1/groups/#{group.id}",
              params: { group: { name: 'Hacked Name' } },
              headers: { 'Authorization' => "Bearer #{other_token}" }

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('You are not authorized to perform this action')
      end
    end

    context 'when group does not exist' do
      it 'returns not found' do
        patch '/api/v1/groups/99999',
              params: { group: { name: 'New Name' } },
              headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        patch "/api/v1/groups/#{group.id}", params: { group: { name: 'New Name' } }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/groups/:id' do
    let!(:group) { create(:group, owner: user, name: 'Group to Delete') }

    context 'when user is the owner' do
      it 'deletes the group' do
        expect {
          delete "/api/v1/groups/#{group.id}", headers: { 'Authorization' => "Bearer #{token}" }
        }.to change(Group, :count).by(-1)

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when user is not the owner' do
      it 'returns forbidden' do
        expect {
          delete "/api/v1/groups/#{group.id}", headers: { 'Authorization' => "Bearer #{other_token}" }
        }.not_to change(Group, :count)

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('You are not authorized to perform this action')
      end
    end

    context 'when group does not exist' do
      it 'returns not found' do
        delete '/api/v1/groups/99999', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        delete "/api/v1/groups/#{group.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
