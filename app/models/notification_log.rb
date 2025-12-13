# frozen_string_literal: true

class NotificationLog < ApplicationRecord
  belongs_to :user

  STATUSES = %w[pending sent failed].freeze
  NOTIFICATION_TYPES = %w[
    reservation_created
    reservation_cancelled
    group_tee_time
    reminder_24h
    reminder_2h
  ].freeze

  validates :notification_type, presence: true, inclusion: { in: NOTIFICATION_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :title, presence: true
  validates :body, presence: true

  scope :pending, -> { where(status: "pending") }
  scope :sent, -> { where(status: "sent") }
  scope :failed, -> { where(status: "failed") }
  scope :recent, -> { order(created_at: :desc) }

  def mark_as_sent!
    update!(status: "sent", sent_at: Time.current)
  end

  def mark_as_failed!(error)
    update!(status: "failed", error_message: error.to_s)
  end
end
