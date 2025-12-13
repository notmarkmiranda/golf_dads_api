# frozen_string_literal: true

class NotificationPreferencePolicy < ApplicationPolicy
  # Users can view their own notification preferences
  def show?
    user.present? && user == record.user
  end

  # Users can update their own notification preferences
  def update?
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
