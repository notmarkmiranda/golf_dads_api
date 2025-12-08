require 'rails_helper'

RSpec.describe TeeTimePosting, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:golf_course).optional }
    it { should have_and_belong_to_many(:groups) }
    it { should have_many(:reservations).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:tee_time_posting) }

    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:tee_time) }
    it { should validate_presence_of(:total_spots) }

    it { should validate_numericality_of(:total_spots).is_greater_than(0) }

    context 'course identification' do
      it 'validates that either course_name or golf_course is present' do
        posting = build(:tee_time_posting, course_name: nil, golf_course: nil)
        expect(posting).not_to be_valid
        expect(posting.errors[:base]).to include('Must specify either course name or golf course')
      end

      it 'is valid with course_name' do
        posting = build(:tee_time_posting, course_name: 'Test Course', golf_course: nil)
        expect(posting).to be_valid
      end

      it 'is valid with golf_course' do
        golf_course = create(:golf_course)
        posting = build(:tee_time_posting, course_name: nil, golf_course: golf_course)
        expect(posting).to be_valid
      end

      it 'is valid with both' do
        golf_course = create(:golf_course)
        posting = build(:tee_time_posting, course_name: 'Test Course', golf_course: golf_course)
        expect(posting).to be_valid
      end
    end

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

    context 'available_spots calculation' do
      it 'calculates available_spots from total_spots and reservations' do
        posting = create(:tee_time_posting, total_spots: 4)
        expect(posting.available_spots).to eq(4)

        # Create a reservation
        create(:reservation, tee_time_posting: posting, spots_reserved: 2)
        posting.reload
        expect(posting.available_spots).to eq(2)
      end

      it 'returns 0 when all spots are reserved' do
        posting = create(:tee_time_posting, total_spots: 4)
        create(:reservation, tee_time_posting: posting, spots_reserved: 4)
        posting.reload
        expect(posting.available_spots).to eq(0)
      end
    end

    context 'group validation' do
      it 'allows posting without a group (public posting)' do
        posting = build(:tee_time_posting)
        expect(posting).to be_valid
      end

      it 'allows posting with a group (group posting)' do
        group = create(:group)
        posting = build(:tee_time_posting)
        posting.groups << group
        expect(posting).to be_valid
      end
    end
  end

  describe 'attributes' do
    it 'has all required attributes' do
      posting = create(:tee_time_posting,
        tee_time: 2.days.from_now,
        course_name: 'Pebble Beach',
        total_spots: 4,
        notes: 'Bring extra balls'
      )

      expect(posting.tee_time).to be_within(1.second).of(2.days.from_now)
      expect(posting.course_name).to eq('Pebble Beach')
      expect(posting.available_spots).to eq(4)  # Calculated from total_spots
      expect(posting.total_spots).to eq(4)
      expect(posting.notes).to eq('Bring extra balls')
    end

    it 'can be created without notes' do
      posting = build(:tee_time_posting, notes: nil)
      expect(posting).to be_valid
    end
  end

  describe 'scopes and queries' do
    let!(:future_posting) { create(:tee_time_posting, tee_time: 2.days.from_now) }
    let!(:past_posting) { create(:tee_time_posting, :past) }
    let!(:group_posting) do
      posting = create(:tee_time_posting, tee_time: 1.day.from_now)
      posting.groups << create(:group)
      posting
    end
    let!(:public_posting) { create(:tee_time_posting, tee_time: 1.day.from_now) }

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
        group_posts = TeeTimePosting.for_group(group_posting.groups.first)
        expect(group_posts).to include(group_posting)
        expect(group_posts).not_to include(public_posting)
      end
    end
  end

  describe '#public?' do
    it 'returns true when posting has no group' do
      posting = build(:tee_time_posting)
      expect(posting.public?).to be true
    end

    it 'returns false when posting has a group' do
      posting = build(:tee_time_posting)
      posting.groups << create(:group)
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

  describe '.near' do
    let!(:pebble_beach) do
      create(:golf_course, name: 'Pebble Beach', latitude: 36.5674, longitude: -121.9500)
    end
    let!(:augusta) do
      create(:golf_course, name: 'Augusta National', latitude: 33.5027, longitude: -82.0201)
    end
    let!(:torrey_pines) do
      create(:golf_course, name: 'Torrey Pines', latitude: 32.9043, longitude: -117.2445)
    end

    let!(:pebble_posting) do
      create(:tee_time_posting, golf_course: pebble_beach, course_name: 'Pebble Beach')
    end
    let!(:augusta_posting) do
      create(:tee_time_posting, golf_course: augusta, course_name: 'Augusta National')
    end
    let!(:torrey_posting) do
      create(:tee_time_posting, golf_course: torrey_pines, course_name: 'Torrey Pines')
    end

    it 'returns postings near a location within radius' do
      # Search near Pebble Beach with 50 mile radius
      nearby = TeeTimePosting.near(latitude: 36.5, longitude: -121.9, radius_miles: 50)
      expect(nearby).to include(pebble_posting)
      expect(nearby).not_to include(augusta_posting)
    end

    it 'excludes postings outside radius' do
      # Search near Pebble Beach with 10 mile radius (should exclude Torrey Pines ~300mi away)
      nearby = TeeTimePosting.near(latitude: 36.5, longitude: -121.9, radius_miles: 10)
      expect(nearby).to include(pebble_posting)
      expect(nearby).not_to include(torrey_posting)
    end

    it 'orders results by distance' do
      # Search from middle point closer to Torrey Pines and Augusta than Pebble Beach
      nearby = TeeTimePosting.near(latitude: 33.0, longitude: -117.0, radius_miles: 500)
      expect(nearby.first).to eq(torrey_posting)
    end

    it 'includes distance_miles in results' do
      nearby = TeeTimePosting.near(latitude: 36.5, longitude: -121.9, radius_miles: 50)
      posting_with_distance = nearby.first
      expect(posting_with_distance).to respond_to(:distance_miles)
      expect(posting_with_distance.distance_miles).to be_a(Numeric)
    end

    it 'only returns postings with associated golf courses' do
      posting_without_course = create(:tee_time_posting, golf_course: nil, course_name: 'Manual Course')
      nearby = TeeTimePosting.near(latitude: 36.5, longitude: -121.9, radius_miles: 1000)
      expect(nearby).not_to include(posting_without_course)
    end
  end
end
