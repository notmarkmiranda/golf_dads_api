class Avo::Resources::Group < Avo::BaseResource
  self.title = :name
  self.includes = [:owner]

  self.search = {
    query: -> { query.where("name ILIKE ?", "%#{q}%") }
  }

  def fields
    field :id, as: :id, link_to_record: true
    field :name, as: :text, required: true
    field :description, as: :textarea, hide_on: [:index]
    field :owner, as: :belongs_to, required: true, searchable: true
    field :created_at, as: :date_time, readonly: true
    field :group_memberships, as: :has_many
    field :members, as: :has_many, through: :group_memberships
    field :tee_time_postings, as: :has_many
  end
end
