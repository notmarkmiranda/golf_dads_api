# frozen_string_literal: true

class GroupPolicy < ApplicationPolicy
  # Authenticated users can view the list of groups
  def index?
    user.present?
  end

  # Users can view groups they own or are members of
  def show?
    user.present? && (owner? || member?)
  end

  # Authenticated users can create groups
  def create?
    user.present?
  end

  # Only the group owner or admins can update the group
  def update?
    user.present? && (owner? || admin?)
  end

  # Only the group owner or admins can destroy the group
  def destroy?
    user.present? && (owner? || admin?)
  end

  # Only the group owner or admins can manage invitations
  def manage_invitations?
    user.present? && (owner? || admin?)
  end

  # Members can attempt to leave (owner check handled in controller)
  def leave?
    user.present? && member?
  end

  # Only owner can remove members
  def remove_member?
    user.present? && owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.present?
        # Return groups the user owns or is a member of
        scope.left_joins(:group_memberships)
             .where('groups.owner_id = ? OR group_memberships.user_id = ?', user.id, user.id)
             .distinct
      else
        scope.none
      end
    end
  end

  private

  def owner?
    user == record.owner
  end

  def member?
    record.members.include?(user)
  end

  def admin?
    user&.admin?
  end
end
