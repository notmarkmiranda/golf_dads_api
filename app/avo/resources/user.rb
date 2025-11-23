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
    field :uid, as: :text, readonly: true, hide_on: [:index], visible: -> { record.oauth_user? }
    field :created_at, as: :date_time, readonly: true
    field :sessions, as: :has_many
  end
end
