module Api
  module V1
    class GroupsController < Api::BaseController
      before_action :set_group, only: [:show, :update, :destroy, :regenerate_code, :tee_time_postings, :leave]

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
        @group.destroy
        head :no_content
      end

      # POST /api/v1/groups/:id/regenerate_code
      # Regenerate the invite code for a group (owner only)
      def regenerate_code
        authorize @group, :update?

        @group.regenerate_invite_code!
        render json: { group: @group.as_json, message: 'Invite code regenerated successfully' }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        error_response(e.message, :unprocessable_entity)
      end

      # GET /api/v1/groups/:id/tee_time_postings
      # Get all tee time postings for a specific group
      def tee_time_postings
        authorize @group, :show?
        @tee_time_postings = TeeTimePosting.for_group(@group)
        render json: { tee_time_postings: @tee_time_postings }, status: :ok
      end

      # POST /api/v1/groups/join_with_code
      # Join a group using an invite code
      def join_with_code
        invite_code = params[:invite_code]

        if invite_code.blank?
          return error_response('Invite code is required', :bad_request)
        end

        group = Group.find_by_invite_code(invite_code)

        if group.nil?
          return error_response('Invalid invite code', :not_found)
        end

        # Check if already a member
        if group.members.include?(current_user)
          return error_response('You are already a member of this group', :unprocessable_entity)
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
      end

      # POST /api/v1/groups/:id/leave
      # Leave a group (members only, not owner)
      def leave
        authorize @group, :leave?

        # Block if user is the owner
        if @group.owner_id == current_user.id
          return error_response(message: 'Owner must transfer ownership before leaving', status: :forbidden)
        end

        # Find and destroy the membership
        membership = @group.group_memberships.find_by(user: current_user)

        if membership.nil?
          return error_response(message: 'You are not a member of this group', status: :unprocessable_entity)
        end

        membership.destroy
        render json: { message: 'Successfully left the group' }, status: :ok
      end

      private

      def set_group
        @group = Group.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        not_found_error_response('Group not found')
      end

      def group_params
        params.require(:group).permit(:name, :description)
      end
    end
  end
end
