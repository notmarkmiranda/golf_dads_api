class GolfCourse < ApplicationRecord
  # Associations
  has_many :tee_time_postings, dependent: :nullify

  # Validations
  validates :name, presence: true
  validates :external_api_id, uniqueness: true, allow_nil: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true

  # Geocoding callback
  after_validation :geocode_address, if: :should_geocode?

  # Scopes
  scope :with_coordinates, -> { where.not(latitude: nil, longitude: nil) }

  # Find courses within radius (uses earthdistance extension)
  # radius in miles
  def self.near(latitude:, longitude:, radius_miles: 25)
    with_coordinates.where(
      "earth_distance(
        ll_to_earth(?, ?),
        ll_to_earth(latitude, longitude)
      ) <= ?",
      latitude,
      longitude,
      radius_miles * 1609.34  # Convert miles to meters
    ).select(
      "golf_courses.*",
      "earth_distance(ll_to_earth(#{latitude}, #{longitude}), ll_to_earth(latitude, longitude)) / 1609.34 AS distance_miles"
    ).order(
      Arel.sql("earth_distance(ll_to_earth(#{latitude}, #{longitude}), ll_to_earth(latitude, longitude))")
    )
  end

  # Calculate distance to a point (returns miles)
  def distance_to(latitude:, longitude:)
    return nil unless self.latitude && self.longitude

    # Use PostGIS earthdistance
    result = ActiveRecord::Base.connection.execute(
      "SELECT earth_distance(
        ll_to_earth(#{latitude}, #{longitude}),
        ll_to_earth(#{self.latitude}, #{self.longitude})
      ) / 1609.34 AS distance"
    ).first

    result["distance"].to_f
  rescue StandardError => e
    Rails.logger.error("Distance calculation error: #{e.message}")
    # Fallback to Ruby Haversine
    haversine_distance(latitude, longitude)
  end

  # Display location as "City, State"
  def display_location
    return "" if city.blank? || state.blank?
    "#{city}, #{state}"
  end

  private

  # Determine if course should be geocoded
  def should_geocode?
    # Only geocode if we don't have coordinates but have address info
    latitude.nil? && longitude.nil? && full_address.present?
  end

  # Build address string from available fields
  def full_address
    parts = [address, city, state, zip_code, country].compact.reject(&:blank?)
    parts.join(", ").presence
  end

  # Geocode address to get lat/lng coordinates
  def geocode_address
    return unless should_geocode?

    result = Geocoder.search(full_address).first
    if result
      self.latitude = result.latitude
      self.longitude = result.longitude
      Rails.logger.info("✓ Geocoded #{name}: #{latitude}, #{longitude}")
    else
      Rails.logger.warn("✗ Could not geocode #{name} with address: #{full_address}")
    end
  rescue Geocoder::Error => e
    # Don't fail the save if geocoding fails
    Rails.logger.error("Geocoding error for #{name}: #{e.message}")
  end

  # Haversine formula in Ruby (fallback)
  def haversine_distance(lat2, lon2)
    rad_per_deg = Math::PI / 180
    earth_radius_miles = 3959

    dlat_rad = (lat2 - latitude) * rad_per_deg
    dlon_rad = (lon2 - longitude) * rad_per_deg

    lat1_rad = latitude * rad_per_deg
    lat2_rad = lat2 * rad_per_deg

    a = Math.sin(dlat_rad / 2)**2 +
        Math.cos(lat1_rad) * Math.cos(lat2_rad) *
        Math.sin(dlon_rad / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    earth_radius_miles * c
  end
end
