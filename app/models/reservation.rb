class Reservation < ApplicationRecord
  belongs_to :user
  belongs_to :tee_time_posting

  validates :user, presence: true
  validates :tee_time_posting, presence: true
  validates :spots_reserved, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :user_id, uniqueness: { scope: :tee_time_posting_id, message: 'has already reserved this tee time' }
  validate :spots_reserved_does_not_exceed_available_spots

  private

  def spots_reserved_does_not_exceed_available_spots
    return unless tee_time_posting && spots_reserved

    # Calculate available spots including this reservation's current spots (if updating)
    available = tee_time_posting.available_spots
    available += spots_reserved_was.to_i if persisted? && spots_reserved_was.present?

    if spots_reserved > available
      errors.add(:spots_reserved, 'cannot exceed available spots on the tee time posting')
    end
  end
end
