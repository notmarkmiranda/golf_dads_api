class ReservationSerializer
  include JSONAPI::Serializer

  attributes :spots_reserved, :created_at, :updated_at

  belongs_to :user
  belongs_to :tee_time_posting
end
