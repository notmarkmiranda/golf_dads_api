class GolfCoursePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all  # All golf courses are public
    end
  end

  def search?
    user.present?  # Must be logged in
  end

  def nearby?
    user.present?
  end

  def cache?
    user.present?
  end
end
