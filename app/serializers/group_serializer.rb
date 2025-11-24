class GroupSerializer
  include JSONAPI::Serializer

  attributes :name, :description, :created_at, :updated_at

  belongs_to :owner, serializer: :user
  has_many :group_memberships
  has_many :members, serializer: :user
  has_many :tee_time_postings
end
