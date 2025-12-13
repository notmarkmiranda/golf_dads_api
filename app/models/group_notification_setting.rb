# frozen_string_literal: true

class GroupNotificationSetting < ApplicationRecord
  belongs_to :user
  belongs_to :group

  validates :user_id, uniqueness: { scope: :group_id }

  scope :muted, -> { where(muted: true) }
  scope :unmuted, -> { where(muted: false) }
end
