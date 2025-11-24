# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  # Anyone can view the list of users (if authenticated)
  def index?
    user.present?
  end

  # Anyone can view user profiles (if authenticated)
  def show?
    user.present?
  end

  # Anyone can create a user (signup - no authentication required)
  def create?
    true
  end

  # Users can update their own profile, admins can update any profile
  def update?
    user.present? && (owner? || admin?)
  end

  # Users can delete their own account, admins can delete any account
  def destroy?
    user.present? && (owner? || admin?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.present?
        scope.all
      else
        scope.none
      end
    end
  end

  private

  def owner?
    user == record
  end

  def admin?
    user&.admin?
  end
end
