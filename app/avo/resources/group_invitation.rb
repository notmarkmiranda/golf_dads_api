class Avo::Resources::GroupInvitation < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :group, as: :belongs_to
    field :inviter, as: :belongs_to
    field :invitee_email, as: :text
    field :status, as: :text
    field :token, as: :text
  end
end
