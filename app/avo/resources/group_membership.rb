class Avo::Resources::GroupMembership < Avo::BaseResource
  self.includes = [:user, :group]

  def fields
    field :id, as: :id, link_to_record: true
    field :user, as: :belongs_to, required: true, searchable: true
    field :group, as: :belongs_to, required: true, searchable: true
    field :created_at, as: :date_time, readonly: true, name: "Joined At"
  end
end
