class TeeTimePosting < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :golf_course, optional: true
  has_and_belongs_to_many :groups
  has_many :reservations, dependent: :destroy

  # Push notification callbacks
  after_create :notify_group_members, if: :has_groups?

  # Validations
  validates :user, presence: true
  validates :tee_time, presence: true
  validates :total_spots, presence: true, numericality: { greater_than: 0 }

  validate :tee_time_must_be_in_future, on: :create
  validate :course_identification_present

  # Scopes
  scope :upcoming, -> { where("tee_time > ?", Time.current) }
  scope :public_postings, -> { left_joins(:groups).where(groups: { id: nil }) }
  scope :for_group, ->(group) { joins(:groups).where(groups: { id: group.id }) }

  # Find postings near a location (uses earthdistance extension)
  scope :near, ->(latitude:, longitude:, radius_miles: 25) {
    lat = latitude.to_f
    lng = longitude.to_f
    distance_calculation = ActiveRecord::Base.sanitize_sql_array([
      "earth_distance(ll_to_earth(?, ?), ll_to_earth(golf_courses.latitude, golf_courses.longitude))",
      lat,
      lng
    ])
    distance_miles = "#{distance_calculation} / 1609.34"

    joins(:golf_course)
      .where.not(golf_courses: { latitude: nil, longitude: nil })
      .where(
        "earth_distance(
          ll_to_earth(?, ?),
          ll_to_earth(golf_courses.latitude, golf_courses.longitude)
        ) <= ?",
        lat,
        lng,
        radius_miles * 1609.34  # Convert miles to meters
      )
      .select(
        "tee_time_postings.*",
        "#{distance_miles} AS distance_miles"
      )
      .reorder(Arel.sql(distance_calculation))
  }

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
    [ total_spots - reservations.reload.sum(:spots_reserved), 0 ].max
  end

  def as_json(options = {})
    result = super(options).merge(
      "group_ids" => group_ids,
      "available_spots" => available_spots
    )

    # Include golf course details if available
    if golf_course
      result["golf_course"] = {
        "id" => golf_course.id,
        "name" => golf_course.name,
        "club_name" => golf_course.club_name,
        "address" => golf_course.address,
        "city" => golf_course.city,
        "state" => golf_course.state,
        "zip_code" => golf_course.zip_code,
        "country" => golf_course.country,
        "latitude" => golf_course.latitude&.to_f,
        "longitude" => golf_course.longitude&.to_f
      }

      # Include distance if it was calculated in scope
      if has_attribute?(:distance_miles)
        result["distance_miles"] = distance_miles&.to_f&.round(1)
      elsif options[:latitude] && options[:longitude] && golf_course.latitude && golf_course.longitude
        # Calculate distance if coordinates provided
        result["distance_miles"] = golf_course.distance_to(
          latitude: options[:latitude],
          longitude: options[:longitude]
        )&.round(1)
      end
    end

    # Include full reservations list for all authenticated users
    if options[:current_user]
      result["reservations"] = reservations.includes(:user).map do |reservation|
        {
          "id" => reservation.id,
          "user_id" => reservation.user_id,
          "user_email" => reservation.user.email_address,
          "spots_reserved" => reservation.spots_reserved,
          "created_at" => reservation.created_at
        }
      end
    end

    result
  end

  private

  def tee_time_must_be_in_future
    return unless tee_time.present?

    if tee_time < Time.current
      errors.add(:tee_time, "must be in the future")
    end
  end

  def course_identification_present
    if course_name.blank? && golf_course.nil?
      errors.add(:base, "Must specify either course name or golf course")
    end
  end

  def has_groups?
    groups.any?
  end

  def notify_group_members
    GroupActivityNotificationJob.perform_later(id)
  end
end
