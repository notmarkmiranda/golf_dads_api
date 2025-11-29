# frozen_string_literal: true

class TeeTimePostingPolicy < ApplicationPolicy
  # Authenticated users can view the list of tee time postings
  def index?
    user.present?
  end

  # Users can view public postings or postings in groups they're members of
  def show?
    user.present? && (public_posting? || creator? || member_of_group?)
  end

  # Authenticated users can create tee time postings
  def create?
    user.present?
  end

  # Only the posting creator or admins can update the posting
  def update?
    user.present? && (creator? || admin?)
  end

  # Only the posting creator or admins can destroy the posting
  def destroy?
    user.present? && (creator? || admin?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.present?
        # Return public postings + postings in user's groups
        scope.left_joins(groups: :group_memberships)
             .where('groups_tee_time_postings.group_id IS NULL OR group_memberships.user_id = ? OR groups.owner_id = ?',
                    user.id, user.id)
             .distinct
      else
        scope.none
      end
    end
  end

  private

  def creator?
    user == record.user
  end

  def public_posting?
    record.groups.empty?
  end

  def member_of_group?
    return false if record.groups.empty?

    record.groups.any? { |group| group.members.include?(user) || group.owner == user }
  end

  def admin?
    user&.admin?
  end
end
