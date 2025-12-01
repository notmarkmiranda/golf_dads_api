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

    if spots_reserved > tee_time_posting.available_spots_calculated
      errors.add(:spots_reserved, 'cannot exceed available spots on the tee time posting')
    end
  end
end
