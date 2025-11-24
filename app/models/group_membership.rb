class GroupMembership < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :group

  # Validations
  validates :user, presence: true
  validates :group, presence: true
  validates :user_id, uniqueness: { scope: :group_id }
end
