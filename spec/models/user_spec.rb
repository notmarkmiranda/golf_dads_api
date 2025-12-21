require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:sessions).dependent(:destroy) }
    it { should have_many(:device_tokens).dependent(:destroy) }
    it { should have_one(:notification_preference).dependent(:destroy) }
    it { should have_many(:group_notification_settings).dependent(:destroy) }
    it { should have_many(:notification_logs).dependent(:destroy) }
  end

  describe 'validations' do
    context 'for all users' do
      subject { build(:user) }

      it { should validate_presence_of(:email_address) }
      it { should validate_uniqueness_of(:email_address).case_insensitive }
      it { should validate_presence_of(:name) }
      it { should allow_value('user@example.com').for(:email_address) }
      it { should_not allow_value('invalid_email').for(:email_address) }
    end

    context 'for password users' do
      subject { build(:user, provider: nil) }

      it { should validate_presence_of(:password) }
      it { should validate_length_of(:password).is_at_least(8) }
    end

    context 'for OAuth users' do
      subject { build(:user, :oauth_user) }

      it 'validates presence of provider when uid is present' do
        user = build(:user, provider: nil, uid: '12345', password: nil)
        expect(user).not_to be_valid
        expect(user.errors[:provider]).to include("can't be blank")
      end

      it 'validates presence of uid when provider is present' do
        user = build(:user, provider: 'google', uid: nil, password: nil)
        expect(user).not_to be_valid
        expect(user.errors[:uid]).to include("can't be blank")
      end
      it 'validates uniqueness of uid scoped to provider' do
        create(:user, :oauth_user, provider: 'google', uid: '12345')
        duplicate_user = build(:user, :oauth_user, provider: 'google', uid: '12345')
        expect(duplicate_user).not_to be_valid
        expect(duplicate_user.errors[:uid]).to include('has already been taken')
      end

      it 'does not require password' do
        user = build(:user, :oauth_user, password: nil)
        expect(user).to be_valid
      end
    end
  end

  describe 'admin functionality' do
    it 'defaults admin to false' do
      user = create(:user)
      expect(user.admin).to be false
    end

    it 'can be set as admin' do
      user = create(:user, admin: true)
      expect(user.admin).to be true
    end

    it 'admin? returns correct value' do
      regular_user = create(:user, admin: false)
      admin_user = create(:user, admin: true, email_address: 'admin@example.com')

      expect(regular_user.admin?).to be false
      expect(admin_user.admin?).to be true
    end
  end

  describe '#oauth_user?' do
    it 'returns true when provider is present' do
      user = build(:user, :oauth_user)
      expect(user.oauth_user?).to be true
    end

    it 'returns false when provider is nil' do
      user = build(:user, provider: nil)
      expect(user.oauth_user?).to be false
    end
  end

  describe '#password_required?' do
    it 'returns true for new password users' do
      user = User.new(provider: nil)
      expect(user.password_required?).to be true
    end

    it 'returns false for OAuth users' do
      user = build(:user, :oauth_user)
      expect(user.password_required?).to be false
    end
  end

  describe '.from_oauth' do
    let(:oauth_params) do
      {
        provider: 'google',
        uid: '12345',
        email: 'user@example.com',
        name: 'John Doe',
        avatar_url: 'https://example.com/avatar.jpg'
      }
    end

    context 'when user does not exist' do
      it 'creates a new user' do
        expect {
          User.from_oauth(**oauth_params)
        }.to change(User, :count).by(1)
      end

      it 'sets the correct attributes' do
        user = User.from_oauth(**oauth_params)
        expect(user.provider).to eq('google')
        expect(user.uid).to eq('12345')
        expect(user.email_address).to eq('user@example.com')
        expect(user.name).to eq('John Doe')
        expect(user.avatar_url).to eq('https://example.com/avatar.jpg')
      end
    end

    context 'when user exists' do
      before do
        User.create!(
          provider: 'google',
          uid: '12345',
          email_address: 'old@example.com',
          name: 'Old Name'
        )
      end

      it 'does not create a new user' do
        expect {
          User.from_oauth(**oauth_params)
        }.not_to change(User, :count)
      end

      it 'updates existing user attributes' do
        user = User.from_oauth(**oauth_params)
        expect(user.email_address).to eq('user@example.com')
        expect(user.name).to eq('John Doe')
        expect(user.avatar_url).to eq('https://example.com/avatar.jpg')
      end
    end
  end

  describe 'email normalization' do
    it 'normalizes email to lowercase' do
      user = create(:user, email_address: 'USER@EXAMPLE.COM')
      expect(user.email_address).to eq('user@example.com')
    end

    it 'strips whitespace from email' do
      user = create(:user, email_address: '  user@example.com  ')
      expect(user.email_address).to eq('user@example.com')
    end
  end

  describe 'password security' do
    it 'hashes the password' do
      user = create(:user, password: 'password123')
      expect(user.password_digest).not_to eq('password123')
      expect(user.password_digest).to be_present
    end

    it 'authenticates with correct password' do
      user = create(:user, password: 'password123')
      expect(user.authenticate('password123')).to eq(user)
    end

    it 'does not authenticate with incorrect password' do
      user = create(:user, password: 'password123')
      expect(user.authenticate('wrong_password')).to be false
    end
  end

  describe '#generate_jwt' do
    let(:user) { create(:user) }

    it 'returns a JWT token string' do
      token = user.generate_jwt
      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3)
    end

    it 'includes user_id in the token payload' do
      token = user.generate_jwt
      decoded = JsonWebToken.decode(token)
      expect(decoded['user_id']).to eq(user.id)
    end

    it 'includes user email in the token payload' do
      token = user.generate_jwt
      decoded = JsonWebToken.decode(token)
      expect(decoded['email']).to eq(user.email_address)
    end

    it 'token expires in 30 days by default' do
      token = user.generate_jwt
      decoded = JsonWebToken.decode(token)
      exp_time = Time.at(decoded['exp'])
      expect(exp_time).to be_within(5.seconds).of(30.days.from_now)
    end
  end

  describe 'notification preferences' do
    it 'creates default notification preference on user creation' do
      user = create(:user)
      expect(user.notification_preference).to be_present
    end

    it 'default notification preference has all notifications enabled' do
      user = create(:user)
      pref = user.notification_preference

      expect(pref.reservations_enabled).to be true
      expect(pref.group_activity_enabled).to be true
      expect(pref.reminders_enabled).to be true
      expect(pref.reminder_24h_enabled).to be true
      expect(pref.reminder_2h_enabled).to be true
    end
  end
end
