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
        expect(group).to have_key('member_names')
      end

      it 'includes member email addresses in member_names' do
        member_user = create(:user, email_address: 'member@example.com')
        create(:group_membership, user: member_user, group: owned_group)

        get '/api/v1/groups', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        my_group = json['groups'].find { |g| g['name'] == 'My Group' }

        expect(my_group['member_names']).to be_an(Array)
        expect(my_group['member_names']).to include('member@example.com')
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
        expect(json['group']).to have_key('member_names')
        expect(json['group']['member_names']).to be_an(Array)
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

      it 'deletes tee time postings that are only visible to this group' do
        # Create a tee time posting that's only in this group
        posting = create(:tee_time_posting, user: user, course_name: 'Test Course')
        posting.groups << group

        expect {
          delete "/api/v1/groups/#{group.id}", headers: { 'Authorization' => "Bearer #{token}" }
        }.to change(TeeTimePosting, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it 'does not delete tee time postings that are visible to multiple groups' do
        # Create another group
        other_group = create(:group, owner: user, name: 'Other Group')

        # Create a tee time posting in both groups
        posting = create(:tee_time_posting, user: user, course_name: 'Test Course')
        posting.groups << [group, other_group]

        expect {
          delete "/api/v1/groups/#{group.id}", headers: { 'Authorization' => "Bearer #{token}" }
        }.not_to change(TeeTimePosting, :count)

        expect(response).to have_http_status(:no_content)

        # Verify the posting still exists and is associated with other_group
        posting.reload
        expect(posting.groups).to include(other_group)
        expect(posting.groups).not_to include(group)
      end

      it 'does not delete public tee time postings (no groups)' do
        # Create a public posting (no groups)
        posting = create(:tee_time_posting, user: user, course_name: 'Test Course')

        expect {
          delete "/api/v1/groups/#{group.id}", headers: { 'Authorization' => "Bearer #{token}" }
        }.not_to change(TeeTimePosting, :count)

        expect(response).to have_http_status(:no_content)
      end

      it 'handles mixed scenario: deletes exclusive postings, preserves shared ones' do
        # Exclusive posting (only in this group)
        exclusive_posting = create(:tee_time_posting, user: user, course_name: 'Exclusive Course')
        exclusive_posting.groups << group

        # Shared posting (in this group and another)
        other_group = create(:group, owner: user, name: 'Other Group')
        shared_posting = create(:tee_time_posting, user: user, course_name: 'Shared Course')
        shared_posting.groups << [group, other_group]

        # Public posting (no groups)
        public_posting = create(:tee_time_posting, user: user, course_name: 'Public Course')

        expect {
          delete "/api/v1/groups/#{group.id}", headers: { 'Authorization' => "Bearer #{token}" }
        }.to change(TeeTimePosting, :count).by(-1)  # Only exclusive posting deleted

        expect(response).to have_http_status(:no_content)

        # Verify exclusive posting is deleted
        expect(TeeTimePosting.exists?(exclusive_posting.id)).to be false

        # Verify shared posting still exists
        expect(TeeTimePosting.exists?(shared_posting.id)).to be true
        shared_posting.reload
        expect(shared_posting.groups).to include(other_group)

        # Verify public posting still exists
        expect(TeeTimePosting.exists?(public_posting.id)).to be true
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

  describe 'POST /api/v1/groups/:id/leave' do
    let!(:group) { create(:group, owner: other_user, name: 'Test Group') }
    let!(:membership) { create(:group_membership, user: user, group: group) }

    context 'when user is a member (not owner)' do
      it 'successfully leaves the group' do
        expect {
          post "/api/v1/groups/#{group.id}/leave", headers: { 'Authorization' => "Bearer #{token}" }
        }.to change(GroupMembership, :count).by(-1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Successfully left the group')

        # Verify membership is removed
        expect(group.members.reload).not_to include(user)
      end
    end

    context 'when user is the owner' do
      let(:owned_group) { create(:group, owner: user, name: 'My Group') }

      before do
        create(:group_membership, user: user, group: owned_group)
      end

      it 'returns forbidden error' do
        expect {
          post "/api/v1/groups/#{owned_group.id}/leave", headers: { 'Authorization' => "Bearer #{token}" }
        }.not_to change(GroupMembership, :count)

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Owner must transfer ownership before leaving')

        # Verify membership still exists
        expect(owned_group.members.reload).to include(user)
      end
    end

    context 'when user is not a member' do
      let(:non_member_group) { create(:group, owner: other_user, name: 'Non-Member Group') }

      it 'returns forbidden' do
        expect {
          post "/api/v1/groups/#{non_member_group.id}/leave", headers: { 'Authorization' => "Bearer #{token}" }
        }.not_to change(GroupMembership, :count)

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('You are not authorized to perform this action')
      end
    end

    context 'when group does not exist' do
      it 'returns not found' do
        post '/api/v1/groups/99999/leave', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Group not found')
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        post "/api/v1/groups/#{group.id}/leave"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/groups/:id/members/:user_id' do
    let!(:group) { create(:group, owner: user, name: 'Test Group') }
    let!(:member_user) { create(:user, email_address: 'member@example.com') }
    let!(:membership) { create(:group_membership, user: member_user, group: group) }

    context 'when user is the owner' do
      it 'successfully removes a member' do
        expect {
          delete "/api/v1/groups/#{group.id}/members/#{member_user.id}", headers: { 'Authorization' => "Bearer #{token}" }
        }.to change(GroupMembership, :count).by(-1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Member removed successfully')

        # Verify membership is removed
        expect(group.members.reload).not_to include(member_user)
      end

      it 'prevents removing the group owner' do
        # Add owner as a member too
        create(:group_membership, user: user, group: group)

        expect {
          delete "/api/v1/groups/#{group.id}/members/#{user.id}", headers: { 'Authorization' => "Bearer #{token}" }
        }.not_to change(GroupMembership, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Cannot remove the group owner')
      end

      it 'returns error when user is not a member' do
        non_member = create(:user, email_address: 'nonmember@example.com')

        expect {
          delete "/api/v1/groups/#{group.id}/members/#{non_member.id}", headers: { 'Authorization' => "Bearer #{token}" }
        }.not_to change(GroupMembership, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('User is not a member of this group')
      end

      it 'returns error when user does not exist' do
        expect {
          delete "/api/v1/groups/#{group.id}/members/99999", headers: { 'Authorization' => "Bearer #{token}" }
        }.not_to change(GroupMembership, :count)

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('User not found')
      end
    end

    context 'when user is not the owner' do
      it 'returns forbidden' do
        expect {
          delete "/api/v1/groups/#{group.id}/members/#{member_user.id}", headers: { 'Authorization' => "Bearer #{other_token}" }
        }.not_to change(GroupMembership, :count)

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('You are not authorized to perform this action')
      end
    end

    context 'when group does not exist' do
      it 'returns not found' do
        delete "/api/v1/groups/99999/members/#{member_user.id}", headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Group not found')
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        delete "/api/v1/groups/#{group.id}/members/#{member_user.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/groups/:id/transfer_ownership' do
    let!(:group) { create(:group, owner: user, name: 'Test Group') }
    let!(:member_user) { create(:user, email_address: 'member@example.com') }
    let!(:membership) { create(:group_membership, user: member_user, group: group) }

    context 'when user is the owner' do
      it 'successfully transfers ownership to a member' do
        post "/api/v1/groups/#{group.id}/transfer_ownership",
             params: { new_owner_id: member_user.id },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Ownership transferred successfully')
        expect(json['group']['owner_id']).to eq(member_user.id)

        # Verify ownership changed in database
        expect(group.reload.owner_id).to eq(member_user.id)
      end

      it 'returns error when new owner is not a member' do
        non_member = create(:user, email_address: 'nonmember@example.com')

        post "/api/v1/groups/#{group.id}/transfer_ownership",
             params: { new_owner_id: non_member.id },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('New owner must be a member of the group')

        # Verify ownership didn't change
        expect(group.reload.owner_id).to eq(user.id)
      end

      it 'returns error when trying to transfer to self' do
        post "/api/v1/groups/#{group.id}/transfer_ownership",
             params: { new_owner_id: user.id },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('User is already the owner')

        # Verify ownership didn't change
        expect(group.reload.owner_id).to eq(user.id)
      end

      it 'returns error when new owner ID is missing' do
        post "/api/v1/groups/#{group.id}/transfer_ownership",
             params: {},
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('New owner ID is required')

        # Verify ownership didn't change
        expect(group.reload.owner_id).to eq(user.id)
      end

      it 'returns error when new owner does not exist' do
        post "/api/v1/groups/#{group.id}/transfer_ownership",
             params: { new_owner_id: 99999 },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('User not found')

        # Verify ownership didn't change
        expect(group.reload.owner_id).to eq(user.id)
      end
    end

    context 'when user is not the owner' do
      it 'returns forbidden' do
        post "/api/v1/groups/#{group.id}/transfer_ownership",
             params: { new_owner_id: member_user.id },
             headers: { 'Authorization' => "Bearer #{other_token}" }

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('You are not authorized to perform this action')

        # Verify ownership didn't change
        expect(group.reload.owner_id).to eq(user.id)
      end
    end

    context 'when group does not exist' do
      it 'returns not found' do
        post '/api/v1/groups/99999/transfer_ownership',
             params: { new_owner_id: member_user.id },
             headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Group not found')
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        post "/api/v1/groups/#{group.id}/transfer_ownership",
             params: { new_owner_id: member_user.id }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/groups/:id/members' do
    let!(:group) { create(:group, owner: user, name: 'Test Group') }
    let!(:member_user1) { create(:user, email_address: 'member1@example.com') }
    let!(:member_user2) { create(:user, email_address: 'member2@example.com') }
    let!(:membership1) { create(:group_membership, user: member_user1, group: group) }
    let!(:membership2) { create(:group_membership, user: member_user2, group: group) }

    context 'when user is a member' do
      it 'returns all members with their details' do
        get "/api/v1/groups/#{group.id}/members",
            headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['members']).to be_an(Array)
        expect(json['members'].length).to eq(2)

        # Check that members have required fields
        member = json['members'].first
        expect(member).to have_key('id')
        expect(member).to have_key('email')
        expect(member).to have_key('name')
        expect(member).to have_key('joined_at')

        # Verify member IDs are included
        member_ids = json['members'].map { |m| m['id'] }
        expect(member_ids).to include(member_user1.id)
        expect(member_ids).to include(member_user2.id)
      end

      it 'includes the owner in the members list' do
        # Owner should also have a membership
        create(:group_membership, user: user, group: group)

        get "/api/v1/groups/#{group.id}/members",
            headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['members'].length).to eq(3)

        member_ids = json['members'].map { |m| m['id'] }
        expect(member_ids).to include(user.id)
      end
    end

    context 'when user is not a member' do
      let!(:non_member_user) { create(:user, email_address: 'nonmember@example.com') }
      let(:non_member_token) { non_member_user.generate_jwt }

      it 'returns forbidden' do
        get "/api/v1/groups/#{group.id}/members",
            headers: { 'Authorization' => "Bearer #{non_member_token}" }

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('You are not authorized to perform this action')
      end
    end

    context 'when group does not exist' do
      it 'returns not found' do
        get '/api/v1/groups/99999/members',
            headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Group not found')
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get "/api/v1/groups/#{group.id}/members"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
