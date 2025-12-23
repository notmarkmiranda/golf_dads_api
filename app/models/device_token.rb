# frozen_string_literal: true

class DeviceToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :platform, presence: true, inclusion: { in: %w[ios android] }
  validate :timezone_must_be_valid, if: :timezone?

  before_save :update_last_used_at

  scope :active, -> { where("last_used_at > ?", 30.days.ago) }
  scope :stale, -> { where("last_used_at <= ? OR last_used_at IS NULL", 30.days.ago) }

  # Get ActiveSupport::TimeZone object for this device
  # Returns nil if timezone is not set or invalid
  def time_zone
    return nil unless timezone.present?
    ActiveSupport::TimeZone[timezone]
  end

  private

  def update_last_used_at
    self.last_used_at = Time.current if new_record? || token_changed?
  end

  def timezone_must_be_valid
    return if timezone.blank?

    unless ActiveSupport::TimeZone[timezone]
      errors.add(:timezone, "is not a valid timezone identifier")
    end
  end
end
