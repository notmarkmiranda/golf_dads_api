class Avo::Resources::TeeTimePosting < Avo::BaseResource
  self.title = :course_name
  self.includes = [ :user, :groups, :golf_course ]

  self.search = {
    query: -> { query.where("course_name ILIKE ? OR notes ILIKE ?", "%#{q}%", "%#{q}%") }
  }

  def fields
    field :id, as: :id, link_to_record: true
    field :user, as: :belongs_to, required: true, searchable: true
    field :golf_course, as: :belongs_to, searchable: true, help: "Link to golf course (optional)"
    field :groups, as: :has_and_belongs_to_many, searchable: true, help: "Leave empty for public posting"
    field :tee_time, as: :date_time, required: true
    field :course_name, as: :text, required: true
    field :total_spots, as: :number, required: true, min: 1, max: 4, help: "Total spots available (1-4)"
    field :available_spots, as: :number, readonly: true, help: "Calculated automatically: total_spots - sum(reservations)"
    field :notes, as: :textarea, hide_on: [ :index ]
    field :created_at, as: :date_time, readonly: true
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :reservations, as: :has_many
  end
end
