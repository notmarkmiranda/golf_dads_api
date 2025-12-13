# frozen_string_literal: true

class DeviceToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :platform, presence: true, inclusion: { in: %w[ios android] }

  before_save :update_last_used_at

  scope :active, -> { where("last_used_at > ?", 30.days.ago) }
  scope :stale, -> { where("last_used_at <= ? OR last_used_at IS NULL", 30.days.ago) }

  private

  def update_last_used_at
    self.last_used_at = Time.current if new_record? || token_changed?
  end
end
