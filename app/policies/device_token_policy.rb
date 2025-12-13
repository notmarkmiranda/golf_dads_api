# frozen_string_literal: true

class DeviceTokenPolicy < ApplicationPolicy
  # Users can create their own device tokens
  def create?
    user.present?
  end

  # Users can delete their own device tokens
  def destroy?
    user.present? && user == record.user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.present?
        scope.where(user: user)
      else
        scope.none
      end
    end
  end
end
