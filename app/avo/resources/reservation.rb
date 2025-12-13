class Avo::Resources::Reservation < Avo::BaseResource
  self.includes = [ :user, :tee_time_posting ]

  def fields
    field :id, as: :id, link_to_record: true
    field :user, as: :belongs_to, required: true, searchable: true
    field :tee_time_posting, as: :belongs_to, required: true, searchable: true
    field :spots_reserved, as: :number, required: true, min: 1, help: "Number of spots to reserve"
    field :created_at, as: :date_time, readonly: true, name: "Reserved At"
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
