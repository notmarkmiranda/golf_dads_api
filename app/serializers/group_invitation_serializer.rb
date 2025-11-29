class GroupInvitationSerializer
  include JSONAPI::Serializer

  attributes :invitee_email, :status, :created_at, :updated_at

  belongs_to :group
  belongs_to :inviter, serializer: :user

  # Don't expose the token for security reasons
  # Token should only be sent via secure channels (email, etc.)
end
