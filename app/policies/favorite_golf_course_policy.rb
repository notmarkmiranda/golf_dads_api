class FavoriteGolfCoursePolicy < ApplicationPolicy
  def index?
    true  # Any authenticated user can list their favorites
  end

  def create?
    true  # Any authenticated user can add favorites
  end

  def destroy?
    # User can only remove their own favorites
    record.user_id == user.id
  end
end
