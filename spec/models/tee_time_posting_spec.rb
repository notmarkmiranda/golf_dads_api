require 'rails_helper'

RSpec.describe TeeTimePosting, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:group).optional }
  end

  describe 'validations' do
    subject { build(:tee_time_posting) }

    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:tee_time) }
    it { should validate_presence_of(:course_name) }
    it { should validate_presence_of(:available_spots) }

    it { should validate_numericality_of(:available_spots).is_greater_than(0) }
    it { should validate_numericality_of(:total_spots).is_greater_than(0).allow_nil }

    context 'tee_time validation' do
      it 'validates tee_time is in the future for new postings' do
        posting = build(:tee_time_posting, tee_time: 1.hour.ago)
        expect(posting).not_to be_valid
        expect(posting.errors[:tee_time]).to include('must be in the future')
      end

      it 'allows tee_time in the future' do
        posting = build(:tee_time_posting, tee_time: 1.day.from_now)
        expect(posting).to be_valid
      end

      it 'does not validate past tee_time for existing postings' do
        posting = create(:tee_time_posting, tee_time: 1.day.from_now)
        posting.update_column(:tee_time, 1.day.ago)
        posting.reload

        posting.course_name = "Updated Course"
        expect(posting).to be_valid
      end
    end

    context 'available_spots validation' do
      it 'validates available_spots is less than or equal to total_spots' do
        posting = build(:tee_time_posting, available_spots: 3, total_spots: 2)
        expect(posting).not_to be_valid
        expect(posting.errors[:available_spots]).to include('must be less than or equal to total spots')
      end

      it 'allows available_spots equal to total_spots' do
        posting = build(:tee_time_posting, available_spots: 4, total_spots: 4)
        expect(posting).to be_valid
      end
    end

    context 'group validation' do
      it 'allows posting without a group (public posting)' do
        posting = build(:tee_time_posting, group: nil)
        expect(posting).to be_valid
      end

      it 'allows posting with a group (group posting)' do
        group = create(:group)
        posting = build(:tee_time_posting, group: group)
        expect(posting).to be_valid
      end
    end
  end

  describe 'attributes' do
    it 'has all required attributes' do
      posting = build(:tee_time_posting,
        tee_time: 2.days.from_now,
        course_name: 'Pebble Beach',
        available_spots: 2,
        total_spots: 4,
        notes: 'Bring extra balls'
      )

      expect(posting.tee_time).to be_within(1.second).of(2.days.from_now)
      expect(posting.course_name).to eq('Pebble Beach')
      expect(posting.available_spots).to eq(2)
      expect(posting.total_spots).to eq(4)
      expect(posting.notes).to eq('Bring extra balls')
    end

    it 'can be created without notes' do
      posting = build(:tee_time_posting, notes: nil)
      expect(posting).to be_valid
    end

    it 'can be created without total_spots' do
      posting = build(:tee_time_posting, total_spots: nil)
      expect(posting).to be_valid
    end
  end

  describe 'scopes and queries' do
    let!(:future_posting) { create(:tee_time_posting, tee_time: 2.days.from_now) }
    let!(:past_posting) { create(:tee_time_posting, :past) }
    let!(:group_posting) { create(:tee_time_posting, group: create(:group), tee_time: 1.day.from_now) }
    let!(:public_posting) { create(:tee_time_posting, group: nil, tee_time: 1.day.from_now) }

    describe '.upcoming' do
      it 'returns postings with tee times in the future' do
        upcoming = TeeTimePosting.upcoming
        expect(upcoming).to include(future_posting)
        expect(upcoming).not_to include(past_posting)
      end
    end

    describe '.public_postings' do
      it 'returns postings without a group' do
        public_posts = TeeTimePosting.public_postings
        expect(public_posts).to include(public_posting)
        expect(public_posts).not_to include(group_posting)
      end
    end

    describe '.for_group' do
      it 'returns postings for a specific group' do
        group_posts = TeeTimePosting.for_group(group_posting.group)
        expect(group_posts).to include(group_posting)
        expect(group_posts).not_to include(public_posting)
      end
    end
  end

  describe '#public?' do
    it 'returns true when posting has no group' do
      posting = build(:tee_time_posting, group: nil)
      expect(posting.public?).to be true
    end

    it 'returns false when posting has a group' do
      posting = build(:tee_time_posting, group: create(:group))
      expect(posting.public?).to be false
    end
  end

  describe '#past?' do
    it 'returns true when tee_time is in the past' do
      posting = create(:tee_time_posting, :past)
      expect(posting.past?).to be true
    end

    it 'returns false when tee_time is in the future' do
      posting = build(:tee_time_posting, tee_time: 1.hour.from_now)
      expect(posting.past?).to be false
    end
  end
end
