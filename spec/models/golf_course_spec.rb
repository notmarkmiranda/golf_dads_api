require 'rails_helper'

RSpec.describe GolfCourse, type: :model do
  describe 'associations' do
    it { should have_many(:tee_time_postings).dependent(:nullify) }
  end

  describe 'validations' do
    subject { build(:golf_course) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:external_api_id).allow_nil }

    context 'coordinate validations' do
      it 'validates latitude range' do
        course = build(:golf_course, latitude: 91)
        expect(course).not_to be_valid
        expect(course.errors[:latitude]).to be_present

        course.latitude = -91
        expect(course).not_to be_valid
        expect(course.errors[:latitude]).to be_present
      end

      it 'validates longitude range' do
        course = build(:golf_course, longitude: 181)
        expect(course).not_to be_valid
        expect(course.errors[:longitude]).to be_present

        course.longitude = -181
        expect(course).not_to be_valid
        expect(course.errors[:longitude]).to be_present
      end

      it 'allows valid coordinates' do
        course = build(:golf_course, latitude: 36.5, longitude: -121.9)
        expect(course).to be_valid
      end

      it 'allows nil coordinates' do
        course = build(:golf_course, latitude: nil, longitude: nil)
        expect(course).to be_valid
      end
    end
  end

  describe '.near' do
    let!(:pebble_beach) { create(:golf_course, :pebble_beach) }
    let!(:augusta) { create(:golf_course, :augusta) }
    let!(:course_without_coords) { create(:golf_course, :without_coordinates) }

    it 'returns courses within radius' do
      # Search near Pebble Beach (36.5674, -121.9500)
      nearby = GolfCourse.near(latitude: 36.5, longitude: -121.9, radius_miles: 50)
      expect(nearby).to include(pebble_beach)
      expect(nearby).not_to include(augusta)
    end

    it 'excludes courses without coordinates' do
      nearby = GolfCourse.near(latitude: 36.5, longitude: -121.9, radius_miles: 1000)
      expect(nearby).not_to include(course_without_coords)
    end

    it 'orders results by distance' do
      # Create a course much closer to search point than existing courses
      close_course = create(:golf_course, latitude: 36.55, longitude: -121.95)
      nearby = GolfCourse.near(latitude: 36.55, longitude: -121.95, radius_miles: 1000)
      # The close_course should be first (essentially 0 distance)
      expect(nearby.first.id).to eq(close_course.id)
      expect(nearby.first.distance_miles).to be_within(0.5).of(0)
    end

    it 'includes distance_miles in results' do
      nearby = GolfCourse.near(latitude: 36.5, longitude: -121.9, radius_miles: 50)
      course_with_distance = nearby.first
      expect(course_with_distance).to respond_to(:distance_miles)
      expect(course_with_distance.distance_miles).to be_a(Numeric)
      expect(course_with_distance.distance_miles).to be >= 0
    end
  end

  describe '#distance_to' do
    let(:pebble_beach) { create(:golf_course, :pebble_beach) }

    it 'calculates distance to coordinates' do
      # Distance from Pebble Beach to Augusta (should be ~2000+ miles)
      distance = pebble_beach.distance_to(latitude: 33.5027, longitude: -82.0201)
      expect(distance).to be > 2000
      expect(distance).to be < 2500
    end

    it 'returns nil if course has no coordinates' do
      course = create(:golf_course, :without_coordinates)
      distance = course.distance_to(latitude: 36.5, longitude: -121.9)
      expect(distance).to be_nil
    end

    it 'returns 0 for same location' do
      distance = pebble_beach.distance_to(
        latitude: pebble_beach.latitude,
        longitude: pebble_beach.longitude
      )
      expect(distance).to be_within(0.1).of(0)
    end
  end

  describe '#display_location' do
    it 'returns city and state when available' do
      course = create(:golf_course, city: 'Pebble Beach', state: 'CA')
      expect(course.display_location).to eq('Pebble Beach, CA')
    end

    it 'returns empty string when city is missing' do
      course = create(:golf_course, city: nil, state: 'CA')
      expect(course.display_location).to eq('')
    end

    it 'returns empty string when state is missing' do
      course = create(:golf_course, city: 'Pebble Beach', state: nil)
      expect(course.display_location).to eq('')
    end
  end
end
