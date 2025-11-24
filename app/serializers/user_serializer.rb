class UserSerializer
  include JSONAPI::Serializer

  attributes :email_address, :name, :avatar_url, :provider, :admin, :created_at, :updated_at

  has_many :group_memberships
  has_many :groups
  has_many :tee_time_postings
  has_many :reservations
end
