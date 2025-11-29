require 'rails_helper'

RSpec.describe GroupInvitation, type: :model do
  describe 'associations' do
    it { should belong_to(:group) }
    it { should belong_to(:inviter).class_name('User') }
  end

  describe 'validations' do
    subject { build(:group_invitation) }

    it { should validate_presence_of(:invitee_email) }
    it { should validate_presence_of(:status) }
    # Token validation is not tested here because callback generates token before validation
    it { should validate_inclusion_of(:status).in_array(%w[pending accepted rejected]) }

    it 'validates email format' do
      invitation = build(:group_invitation, invitee_email: 'invalid')
      expect(invitation).not_to be_valid
      expect(invitation.errors[:invitee_email]).to be_present
    end

    it 'validates uniqueness of pending invitations' do
      invitation1 = create(:group_invitation, invitee_email: 'test@example.com', status: 'pending')
      invitation2 = build(:group_invitation, group: invitation1.group, invitee_email: 'test@example.com', status: 'pending')

      expect(invitation2).not_to be_valid
      expect(invitation2.errors[:group_id]).to be_present
    end

    it 'allows multiple invitations for same email if not pending' do
      invitation1 = create(:group_invitation, invitee_email: 'test@example.com', status: 'accepted')
      invitation2 = build(:group_invitation, group: invitation1.group, invitee_email: 'test@example.com', status: 'pending')

      expect(invitation2).to be_valid
    end
  end

  describe 'callbacks' do
    it 'generates token before validation on create' do
      invitation = build(:group_invitation, token: nil)
      expect(invitation.token).to be_nil
      invitation.valid?
      expect(invitation.token).to be_present
    end

    it 'does not regenerate token if already set' do
      token = SecureRandom.urlsafe_base64(32)
      invitation = build(:group_invitation, token: token)
      invitation.valid?
      expect(invitation.token).to eq(token)
    end
  end

  describe 'scopes' do
    let!(:pending_invitation) { create(:group_invitation, status: 'pending') }
    let!(:accepted_invitation) { create(:group_invitation, status: 'accepted') }
    let!(:rejected_invitation) { create(:group_invitation, status: 'rejected') }

    describe '.pending' do
      it 'returns only pending invitations' do
        expect(GroupInvitation.pending).to include(pending_invitation)
        expect(GroupInvitation.pending).not_to include(accepted_invitation, rejected_invitation)
      end
    end

    describe '.accepted' do
      it 'returns only accepted invitations' do
        expect(GroupInvitation.accepted).to include(accepted_invitation)
        expect(GroupInvitation.accepted).not_to include(pending_invitation, rejected_invitation)
      end
    end

    describe '.rejected' do
      it 'returns only rejected invitations' do
        expect(GroupInvitation.rejected).to include(rejected_invitation)
        expect(GroupInvitation.rejected).not_to include(pending_invitation, accepted_invitation)
      end
    end

    describe '.for_email' do
      it 'returns invitations for specific email' do
        expect(GroupInvitation.for_email(pending_invitation.invitee_email)).to include(pending_invitation)
        expect(GroupInvitation.for_email('other@example.com')).not_to include(pending_invitation)
      end
    end
  end

  describe '#accept!' do
    let(:group) { create(:group) }
    let(:user) { create(:user) }
    let(:invitation) { create(:group_invitation, group: group, invitee_email: user.email_address, status: 'pending') }

    it 'accepts invitation and creates membership' do
      expect(invitation.accept!(user)).to be true
      expect(invitation.reload.status).to eq('accepted')
      expect(group.members).to include(user)
    end

    it 'returns false if invitation is not pending' do
      invitation.update!(status: 'accepted')
      expect(invitation.accept!(user)).to be false
    end

    it 'returns false if email does not match' do
      other_user = create(:user, email_address: 'different@example.com')
      expect(invitation.accept!(other_user)).to be false
    end
  end

  describe '#reject!' do
    let(:invitation) { create(:group_invitation, status: 'pending') }

    it 'rejects invitation' do
      expect(invitation.reject!).to be true
      expect(invitation.reload.status).to eq('rejected')
    end

    it 'returns false if invitation is not pending' do
      invitation.update!(status: 'accepted')
      expect(invitation.reject!).to be false
    end
  end

  describe 'status predicates' do
    it '#pending? returns true for pending invitations' do
      invitation = build(:group_invitation, status: 'pending')
      expect(invitation.pending?).to be true
      expect(invitation.accepted?).to be false
      expect(invitation.rejected?).to be false
    end

    it '#accepted? returns true for accepted invitations' do
      invitation = build(:group_invitation, status: 'accepted')
      expect(invitation.accepted?).to be true
      expect(invitation.pending?).to be false
      expect(invitation.rejected?).to be false
    end

    it '#rejected? returns true for rejected invitations' do
      invitation = build(:group_invitation, status: 'rejected')
      expect(invitation.rejected?).to be true
      expect(invitation.pending?).to be false
      expect(invitation.accepted?).to be false
    end
  end
end
