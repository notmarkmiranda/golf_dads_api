class User < ApplicationRecord
  has_secure_password validations: false
  has_many :sessions, dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :tee_time_postings, dependent: :destroy
  has_many :reservations, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Validations
  validates :email_address, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, presence: true, length: { minimum: 8 }, if: :password_required?
  validates :provider, presence: true, if: -> { uid.present? }
  validates :uid, presence: true, uniqueness: { scope: :provider }, if: -> { provider.present? }

  # OAuth methods
  def oauth_user?
    provider.present?
  end

  def password_required?
    !oauth_user? && (password_digest.nil? || password.present?)
  end

  # Find or create OAuth user
  def self.from_oauth(provider:, uid:, email:, name:, avatar_url: nil)
    user = find_or_initialize_by(provider: provider, uid: uid)
    user.assign_attributes(
      email_address: email,
      name: name,
      avatar_url: avatar_url
    )
    user.save!
    user
  end

  # Generate JWT token for API authentication
  def generate_jwt
    JsonWebToken.encode({
      user_id: id,
      email: email_address
    })
  end
end
