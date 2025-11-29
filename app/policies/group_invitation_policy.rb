# frozen_string_literal: true

class GroupInvitationPolicy < ApplicationPolicy
  # Authenticated users can view their own invitations
  def index?
    user.present?
  end

  # Users can view invitations sent to them or sent by their groups
  def show?
    user.present? && (invitee? || group_owner? || group_admin?)
  end

  # Group owners and admins can create invitations (handled in GroupPolicy#manage_invitations?)
  def create?
    user.present? && (group_owner? || group_admin?)
  end

  # Users can accept invitations sent to their email
  def accept?
    user.present? && invitee? && record.pending?
  end

  # Users can reject invitations sent to their email
  def reject?
    user.present? && invitee? && record.pending?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.present?
        # Return invitations sent to the user's email
        scope.where(invitee_email: user.email_address)
      else
        scope.none
      end
    end
  end

  private

  def invitee?
    record.invitee_email.downcase == user.email_address.downcase
  end

  def group_owner?
    user == record.group.owner
  end

  def group_admin?
    user&.admin?
  end
end
