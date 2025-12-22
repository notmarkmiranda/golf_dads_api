module Api
  module V1
    class GroupsController < Api::BaseController
      before_action :set_group, only: [ :show, :update, :destroy, :regenerate_code, :tee_time_postings, :leave, :remove_member, :transfer_ownership, :members, :update_notification_settings ]

      # GET /api/v1/groups
      def index
        authorize Group
        @groups = policy_scope(Group)
        render json: { groups: @groups.as_json }, status: :ok
      end

      # GET /api/v1/groups/:id
      def show
        authorize @group
        render json: { group: @group.as_json }, status: :ok
      end

      # POST /api/v1/groups
      def create
        authorize Group
        @group = current_user.owned_groups.build(group_params)

        if @group.save
          # Automatically add the owner as a member
          GroupMembership.create!(group: @group, user: current_user)

          render json: { group: @group.as_json }, status: :created
        else
          validation_error_response(@group.errors.messages)
        end
      end

      # PATCH/PUT /api/v1/groups/:id
      def update
        authorize @group

        if @group.update(group_params)
          render json: { group: @group.as_json }, status: :ok
        else
          validation_error_response(@group.errors.messages)
        end
      end

      # DELETE /api/v1/groups/:id
      def destroy
        authorize @group

        # Delete tee time postings that are only visible to this group
        @group.tee_time_postings.each do |posting|
          # Only delete if this is the only group the posting is visible to
          if posting.groups.count == 1
            posting.destroy
          end
        end

        @group.destroy
        head :no_content
      end

      # POST /api/v1/groups/:id/regenerate_code
      # Regenerate the invite code for a group (owner only)
      def regenerate_code
        authorize @group, :update?

        @group.regenerate_invite_code!
        render json: { group: @group.as_json, message: "Invite code regenerated successfully" }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        error_response(e.message, :unprocessable_entity)
      end

      # GET /api/v1/groups/:id/tee_time_postings
      # Get all tee time postings for a specific group
      def tee_time_postings
        authorize @group, :show?
        # Only show tee times from last 6 hours onwards (hide old past tee times)
        @tee_time_postings = TeeTimePosting.for_group(@group).recent
        render json: { tee_time_postings: @tee_time_postings }, status: :ok
      end

      # POST /api/v1/groups/join_with_code
      # Join a group using an invite code
      def join_with_code
        # Require authentication
        return unless require_authentication

        invite_code = params[:invite_code]

        # Sanitize: strip whitespace and upcase to match stored format
        invite_code = invite_code&.strip&.upcase

        if invite_code.blank?
          return error_response(message: "Invite code is required", status: :bad_request)
        end

        group = Group.find_by_invite_code(invite_code)

        if group.nil?
          return error_response(message: "Invalid invite code", status: :not_found)
        end

        # Check if already a member
        if group.members.include?(current_user)
          return error_response(message: "You are already a member of this group", status: :unprocessable_entity)
        end

        # Add user to group
        group_membership = GroupMembership.new(group: group, user: current_user)

        if group_membership.save
          render json: {
            group: group.as_json,
            message: "Successfully joined #{group.name}"
          }, status: :ok
        else
          validation_error_response(group_membership.errors.messages)
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Join group validation error: #{e.message}"
        validation_error_response(e.record.errors.messages)
      rescue StandardError => e
        Rails.logger.error "Join group error: #{e.class} - #{e.message}"
        error_response(
          message: "Unable to join group. Please try again.",
          status: :internal_server_error
        )
      end

      # POST /api/v1/groups/:id/leave
      # Leave a group (members only, not owner)
      def leave
        authorize @group, :leave?

        # Block if user is the owner
        if @group.owner_id == current_user.id
          return error_response(message: "Owner must transfer ownership before leaving", status: :forbidden)
        end

        # Find and destroy the membership
        membership = @group.group_memberships.find_by(user: current_user)

        if membership.nil?
          return error_response(message: "You are not a member of this group", status: :unprocessable_entity)
        end

        membership.destroy

        # Regenerate invite code for security when a member leaves
        @group.regenerate_invite_code!

        render json: { message: "Successfully left the group" }, status: :ok
      end

      # DELETE /api/v1/groups/:group_id/members/:user_id
      # Remove a member from the group (owner only)
      def remove_member
        authorize @group, :remove_member?

        user_id = params[:user_id]

        # Find the user to remove
        user_to_remove = User.find(user_id)

        # Prevent removing the owner
        if user_to_remove.id == @group.owner_id
          return error_response(message: "Cannot remove the group owner", status: :unprocessable_entity)
        end

        # Find and destroy the membership
        membership = @group.group_memberships.find_by(user: user_to_remove)

        if membership.nil?
          return error_response(message: "User is not a member of this group", status: :unprocessable_entity)
        end

        membership.destroy
        render json: { message: "Member removed successfully" }, status: :ok
      rescue ActiveRecord::RecordNotFound
        error_response(message: "User not found", status: :not_found)
      end

      # POST /api/v1/groups/:id/transfer_ownership
      # Transfer ownership to another member (owner only)
      def transfer_ownership
        authorize @group, :transfer_ownership?

        new_owner_id = params[:new_owner_id]

        if new_owner_id.blank?
          return error_response(message: "New owner ID is required", status: :bad_request)
        end

        # Find the new owner
        new_owner = User.find(new_owner_id)

        # Prevent transferring to self (check before membership)
        if new_owner.id == @group.owner_id
          return error_response(message: "User is already the owner", status: :unprocessable_entity)
        end

        # Verify new owner is a member
        unless @group.members.include?(new_owner)
          return error_response(message: "New owner must be a member of the group", status: :unprocessable_entity)
        end

        # Transfer ownership
        @group.update!(owner: new_owner)

        render json: { group: @group.as_json, message: "Ownership transferred successfully" }, status: :ok
      rescue ActiveRecord::RecordNotFound
        error_response(message: "User not found", status: :not_found)
      rescue ActiveRecord::RecordInvalid => e
        error_response(message: e.message, status: :unprocessable_entity)
      end

      # GET /api/v1/groups/:id/members
      # Get all members of the group with their details
      def members
        authorize @group, :show?

        members_data = @group.members.map do |member|
          membership = @group.group_memberships.find_by(user: member)
          {
            id: member.id,
            email: member.email_address,
            name: member.email_address.split("@").first,
            joined_at: membership.created_at
          }
        end

        render json: { members: members_data }, status: :ok
      end

      # PATCH /api/v1/groups/:id/notification_settings
      # Update notification settings for the current user in this group
      def update_notification_settings
        authorize @group, :show?

        setting = current_user.group_notification_settings.find_or_initialize_by(group: @group)

        if setting.update(notification_settings_params)
          render json: group_notification_setting_response(setting), status: :ok
        else
          validation_error_response(setting.errors.messages)
        end
      end

      private

      def set_group
        @group = Group.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        not_found_error_response("Group not found")
      end

      def group_params
        params.require(:group).permit(:name, :description)
      end

      def notification_settings_params
        params.require(:notification_settings).permit(:muted)
      end

      def group_notification_setting_response(setting)
        {
          id: setting.id,
          user_id: setting.user_id,
          group_id: setting.group_id,
          muted: setting.muted
        }
      end
    end
  end
end
