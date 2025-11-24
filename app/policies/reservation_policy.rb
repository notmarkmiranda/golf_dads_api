# frozen_string_literal: true

class ReservationPolicy < ApplicationPolicy
  # Authenticated users can view the list of reservations
  def index?
    user.present?
  end

  # Users can view their own reservations or reservations on their postings
  def show?
    user.present? && (reserver? || posting_creator?)
  end

  # Authenticated users can create reservations
  def create?
    user.present?
  end

  # Only the reserver or admins can update the reservation
  def update?
    user.present? && (reserver? || admin?)
  end

  # The reserver, posting creator, or admins can destroy the reservation
  def destroy?
    user.present? && (reserver? || posting_creator? || admin?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.present?
        # Return user's own reservations + reservations on their postings
        scope.left_joins(:tee_time_posting)
             .where('reservations.user_id = ? OR tee_time_postings.user_id = ?', user.id, user.id)
             .distinct
      else
        scope.none
      end
    end
  end

  private

  def reserver?
    user == record.user
  end

  def posting_creator?
    user == record.tee_time_posting.user
  end

  def admin?
    user&.admin?
  end
end
