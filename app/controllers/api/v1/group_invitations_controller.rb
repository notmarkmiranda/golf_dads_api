module Api
  module V1
    class GroupInvitationsController < Api::BaseController
      before_action :set_invitation, only: [:show, :accept, :reject]
      before_action :set_group, only: [:create, :index_for_group]

      # GET /api/v1/group_invitations
      # Get all invitations for the current user (received)
      def index
        authorize GroupInvitation
        @invitations = GroupInvitation.for_email(current_user.email_address).pending
        render json: { group_invitations: @invitations }, status: :ok
      end

      # GET /api/v1/groups/:group_id/invitations
      # Get all invitations sent for a specific group
      def index_for_group
        authorize @group, :manage_invitations?
        @invitations = @group.group_invitations
        render json: { group_invitations: @invitations }, status: :ok
      end

      # GET /api/v1/group_invitations/:id
      def show
        authorize @invitation
        render json: { group_invitation: @invitation }, status: :ok
      end

      # POST /api/v1/groups/:group_id/invitations
      def create
        authorize @group, :manage_invitations?

        @invitation = @group.group_invitations.build(invitation_params)
        @invitation.inviter = current_user

        if @invitation.save
          # TODO: Send invitation email here
          render json: { group_invitation: @invitation }, status: :created
        else
          validation_error_response(@invitation.errors.messages)
        end
      end

      # POST /api/v1/group_invitations/:id/accept
      def accept
        authorize @invitation

        if @invitation.accept!(current_user)
          render json: {
            group_invitation: @invitation,
            message: 'Successfully joined the group'
          }, status: :ok
        else
          error_response('Unable to accept invitation', :unprocessable_entity)
        end
      end

      # POST /api/v1/group_invitations/:id/reject
      def reject
        authorize @invitation

        if @invitation.reject!
          render json: {
            group_invitation: @invitation,
            message: 'Invitation rejected'
          }, status: :ok
        else
          error_response('Unable to reject invitation', :unprocessable_entity)
        end
      end

      private

      def set_invitation
        @invitation = GroupInvitation.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        not_found_error_response('Group invitation not found')
      end

      def set_group
        @group = Group.find(params[:group_id])
      rescue ActiveRecord::RecordNotFound
        not_found_error_response('Group not found')
      end

      def invitation_params
        params.require(:group_invitation).permit(:invitee_email)
      end
    end
  end
end
