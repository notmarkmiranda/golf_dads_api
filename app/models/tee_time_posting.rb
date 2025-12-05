class TeeTimePosting < ApplicationRecord
  # Associations
  belongs_to :user
  has_and_belongs_to_many :groups
  has_many :reservations, dependent: :destroy

  # Validations
  validates :user, presence: true
  validates :tee_time, presence: true
  validates :course_name, presence: true
  validates :total_spots, presence: true, numericality: { greater_than: 0 }

  validate :tee_time_must_be_in_future, on: :create

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

  # Always calculate available spots dynamically based on total_spots and reservations
  # This overrides the database column
  def available_spots
    return 0 unless total_spots
    [total_spots - reservations.reload.sum(:spots_reserved), 0].max
  end

  def as_json(options = {})
    result = super(options).merge(
      'group_ids' => group_ids,
      'available_spots' => available_spots
    )

    # Include full reservations list if current_user is the owner
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
    # For non-owners, include only their own reservation if they have one
    elsif options[:current_user]
      user_reservation = reservations.find_by(user_id: options[:current_user].id)
      if user_reservation
        result['reservations'] = [{
          'id' => user_reservation.id,
          'user_id' => user_reservation.user_id,
          'user_email' => options[:current_user].email_address,
          'spots_reserved' => user_reservation.spots_reserved,
          'created_at' => user_reservation.created_at
        }]
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
end
