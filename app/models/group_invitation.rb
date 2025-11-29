class GroupInvitation < ApplicationRecord
  # Associations
  belongs_to :group
  belongs_to :inviter, class_name: 'User'

  # Validations
  validates :invitee_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, presence: true, inclusion: { in: %w[pending accepted rejected] }
  validates :token, presence: true, uniqueness: true
  validates :group_id, uniqueness: { scope: [:invitee_email, :status],
                                      message: "already has a pending invitation for this email",
                                      conditions: -> { where(status: 'pending') } }

  # Callbacks
  before_validation :generate_token, on: :create

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :accepted, -> { where(status: 'accepted') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :for_email, ->(email) { where(invitee_email: email) }

  # Instance methods
  def accept!(user)
    return false unless pending?
    return false if invitee_email.downcase != user.email_address.downcase

    transaction do
      update!(status: 'accepted')
      GroupMembership.create!(group: group, user: user)
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def reject!
    return false unless pending?
    update(status: 'rejected')
  end

  def pending?
    status == 'pending'
  end

  def accepted?
    status == 'accepted'
  end

  def rejected?
    status == 'rejected'
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end
end
