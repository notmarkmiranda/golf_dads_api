require 'rails_helper'

RSpec.describe 'Api::V1::Groups - Notification Settings', type: :request do
  let(:owner) { create(:user) }
  let(:member) { create(:user) }
  let(:group) { create(:group, owner: owner) }
  let(:token) { member.generate_jwt }
  let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

  before do
    create(:group_membership, user: owner, group: group)
    create(:group_membership, user: member, group: group)
  end

  describe 'PATCH /api/v1/groups/:id/notification_settings' do
    context 'with valid authentication as group member' do
      it 'creates notification settings for the group' do
        expect {
          patch "/api/v1/groups/#{group.id}/notification_settings",
            params: { notification_settings: { muted: true } },
            headers: auth_headers,
            as: :json
        }.to change(GroupNotificationSetting, :count).by(1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['user_id']).to eq(member.id)
        expect(json['group_id']).to eq(group.id)
        expect(json['muted']).to eq(true)
      end

      it 'updates existing notification settings' do
        setting = create(:group_notification_setting, user: member, group: group, muted: false)

        expect {
          patch "/api/v1/groups/#{group.id}/notification_settings",
            params: { notification_settings: { muted: true } },
            headers: auth_headers,
            as: :json
        }.not_to change(GroupNotificationSetting, :count)

        expect(response).to have_http_status(:ok)
        setting.reload
        expect(setting.muted).to eq(true)
      end

      it 'unmutes group notifications' do
        setting = create(:group_notification_setting, user: member, group: group, muted: true)

        patch "/api/v1/groups/#{group.id}/notification_settings",
          params: { notification_settings: { muted: false } },
          headers: auth_headers,
          as: :json

        expect(response).to have_http_status(:ok)
        setting.reload
        expect(setting.muted).to eq(false)
      end
    end

    context 'without authentication' do
      it 'returns unauthorized error' do
        patch "/api/v1/groups/#{group.id}/notification_settings",
          params: { notification_settings: { muted: true } },
          as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'for non-existent group' do
      it 'returns not found error' do
        patch "/api/v1/groups/99999/notification_settings",
          params: { notification_settings: { muted: true } },
          headers: auth_headers,
          as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'as non-member' do
      let(:non_member) { create(:user) }
      let(:non_member_token) { non_member.generate_jwt }
      let(:non_member_headers) { { 'Authorization' => "Bearer #{non_member_token}" } }

      it 'returns forbidden error' do
        patch "/api/v1/groups/#{group.id}/notification_settings",
          params: { notification_settings: { muted: true } },
          headers: non_member_headers,
          as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
