class User < ApplicationRecord
  has_secure_password validations: false
  has_many :sessions, dependent: :destroy
  has_many :owned_groups, class_name: 'Group', foreign_key: 'owner_id', dependent: :destroy
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
  validates :google_id, uniqueness: true, allow_nil: true
  validates :venmo_handle, format: { with: /\A@/, message: "must start with @" }, allow_nil: true
  validates :handicap, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 54.0 }, allow_nil: true

  # Normalize venmo_handle to always start with @
  normalizes :venmo_handle, with: ->(v) {
    return nil if v.blank?
    v.start_with?('@') ? v : "@#{v}"
  }

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

  # Find or create user from Google auth
  def self.from_google_auth(user_info)
    # First try to find by google_id
    user = find_by(google_id: user_info[:google_id])
    return user if user

    # If not found, try to find by email
    user = find_by(email_address: user_info[:email])

    if user
      # Link existing email/password account to Google
      user.update(google_id: user_info[:google_id])
      user
    else
      # Create new user from Google auth
      create!(
        google_id: user_info[:google_id],
        email_address: user_info[:email],
        name: user_info[:name],
        avatar_url: user_info[:picture],
        # Set provider/uid for OAuth tracking
        provider: 'google',
        uid: user_info[:google_id],
        # No password needed for Google auth users
        password_digest: nil
      )
    end
  end

  # Check if user signed up with Google
  def google_user?
    google_id.present?
  end

  # Generate JWT token for API authentication
  def generate_jwt(exp: nil)
    JsonWebToken.encode({
      user_id: id,
      email: email_address
    }, exp: exp)
  end
end
