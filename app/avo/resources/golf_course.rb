class Avo::Resources::GolfCourse < Avo::BaseResource
  self.title = :name
  self.includes = []

  self.search = {
    query: -> { query.where("name ILIKE ? OR city ILIKE ? OR state ILIKE ?", "%#{q}%", "%#{q}%", "%#{q}%") }
  }

  def fields
    field :id, as: :id, link_to_record: true
    field :name, as: :text, required: true
    field :club_name, as: :text
    field :address, as: :text
    field :city, as: :text
    field :state, as: :text
    field :zip_code, as: :text
    field :country, as: :text
    field :latitude, as: :number, help: "Decimal degrees"
    field :longitude, as: :number, help: "Decimal degrees"
    field :external_id, as: :text, readonly: true, help: "ID from external Golf Course API"
    field :phone, as: :text
    field :website, as: :text
    field :created_at, as: :date_time, readonly: true
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :tee_time_postings, as: :has_many
  end
end
