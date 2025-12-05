class TeeTimePosting < ApplicationRecord
  # Associations
  belongs_to :user
  has_and_belongs_to_many :groups
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
  scope :public_postings, -> { left_joins(:groups).where(groups: { id: nil }) }
  scope :for_group, ->(group) { joins(:groups).where(groups: { id: group.id }) }

  # Instance methods
  def public?
    groups.empty?
  end

  def past?
    tee_time < Time.current
  end

  # Calculate available spots dynamically based on total_spots and reservations
  def available_spots_calculated
    return available_spots unless total_spots

    total_spots - reservations.sum(:spots_reserved)
  end

  def as_json(options = {})
    result = super(options).merge(
      'group_ids' => group_ids,
      'available_spots' => available_spots_calculated
    )

    # Include reservations only if current_user is the owner
    if options[:current_user] && options[:current_user].id == user_id
      result['reservations'] = reservations.includes(:user).map do |reservation|
        {
          'id' => reservation.id,
          'user_id' => reservation.user_id,
          'user_email' => reservation.user.email_address,
          'spots_reserved' => reservation.spots_reserved,
          'created_at' => reservation.created_at
        }
      end
    end

    result
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
