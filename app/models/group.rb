class Group < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: 'User'
  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships, source: :user
  has_and_belongs_to_many :tee_time_postings

  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { scope: :owner_id }
  validates :owner, presence: true
  validates :invite_code, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_invite_code, on: :create

  # Instance methods
  def regenerate_invite_code!
    update!(invite_code: self.class.generate_unique_code)
  end

  def as_json(options = {})
    super(options).merge(
      'member_names' => members.pluck(:email_address)
    )
  end

  # Class methods
  def self.find_by_invite_code(code)
    find_by(invite_code: code&.upcase)
  end

  def self.generate_unique_code
    loop do
      code = SecureRandom.alphanumeric(8).upcase
      break code unless exists?(invite_code: code)
    end
  end

  private

  def generate_invite_code
    self.invite_code ||= self.class.generate_unique_code
  end
end
