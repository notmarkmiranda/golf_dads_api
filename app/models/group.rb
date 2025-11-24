class Group < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: 'User'
  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships, source: :user
  has_many :tee_time_postings, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { scope: :owner_id }
  validates :owner, presence: true
end
