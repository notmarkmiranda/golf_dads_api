class TeeTimePosting < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :group, optional: true
  has_many :reservations, dependent: :destroy

  # Validations
  validates :user, presence: true
  validates :tee_time, presence: true
  validates :course_name, presence: true
  validates :available_spots, presence: true,
            numericality: { greater_than: 0 }
  validates :total_spots, numericality: { greater_than: 0 }, allow_nil: true

  validate :tee_time_must_be_in_future, on: :create
  validate :available_spots_must_not_exceed_total_spots

  # Scopes
  scope :upcoming, -> { where('tee_time > ?', Time.current) }
  scope :public_postings, -> { where(group_id: nil) }
  scope :for_group, ->(group) { where(group: group) }

  # Instance methods
  def public?
    group_id.nil?
  end

  def past?
    tee_time < Time.current
  end

  private

  def tee_time_must_be_in_future
    return unless tee_time.present?

    if tee_time < Time.current
      errors.add(:tee_time, 'must be in the future')
    end
  end

  def available_spots_must_not_exceed_total_spots
    return unless available_spots.present? && total_spots.present?

    if available_spots > total_spots
      errors.add(:available_spots, 'must be less than or equal to total spots')
    end
  end
end
