class TeeTimePostingSerializer
  include JSONAPI::Serializer

  attributes :tee_time, :course_name, :available_spots, :total_spots, :notes, :created_at, :updated_at

  belongs_to :user
  belongs_to :group, serializer: :group
  has_many :reservations

  # Add computed attributes
  attribute :public do |posting|
    posting.public?
  end

  attribute :past do |posting|
    posting.past?
  end
end
