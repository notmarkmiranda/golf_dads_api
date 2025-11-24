class Avo::Resources::User < Avo::BaseResource
  self.title = :name
  self.includes = []

  self.search = {
    query: -> { query.where("email_address ILIKE ? OR name ILIKE ?", "%#{q}%", "%#{q}%") }
  }

  def fields
    field :id, as: :id, link_to_record: true
    field :avatar_url, as: :external_image, hide_on: [:index]
    field :name, as: :text, required: true
    field :email_address, as: :text, required: true, name: "Email"
    field :provider, as: :badge, readonly: true do
      record.provider || "Password"
    end
    field :uid, as: :text, readonly: true, hide_on: [:index, :new, :edit]
    field :password, as: :password, name: "Password", only_on: [:new, :edit], help: "Minimum 8 characters"
    field :password_confirmation, as: :password, name: "Password Confirmation", only_on: [:new, :edit]
    field :created_at, as: :date_time, readonly: true
    field :updated_at, as: :date_time, readonly: true, hide_on: [:index]
    field :sessions, as: :has_many
    field :group_memberships, as: :has_many
    field :groups, as: :has_many, through: :group_memberships
    field :tee_time_postings, as: :has_many
    field :reservations, as: :has_many
  end
end
