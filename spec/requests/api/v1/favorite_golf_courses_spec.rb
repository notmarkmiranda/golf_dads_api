require 'rails_helper'

RSpec.describe "Api::V1::FavoriteGolfCourses", type: :request do
  let(:user) { create(:user) }
  let(:token) { user.generate_jwt }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }
  let(:golf_course) { create(:golf_course) }

  describe "GET /api/v1/favorite_golf_courses" do
    it "returns empty array when no favorites" do
      get "/api/v1/favorite_golf_courses", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response[:golf_courses]).to eq([])
    end

    it "returns user's favorite courses" do
      favorite = create(:favorite_golf_course, user: user, golf_course: golf_course)

      get "/api/v1/favorite_golf_courses", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response[:golf_courses].length).to eq(1)
      expect(json_response[:golf_courses][0][:id]).to eq(golf_course.id)
      expect(json_response[:golf_courses][0][:is_favorite]).to eq(true)
    end

    it "returns courses in reverse chronological order" do
      course1 = create(:golf_course, name: "First Course")
      course2 = create(:golf_course, name: "Second Course")

      # Create favorites in specific order
      create(:favorite_golf_course, user: user, golf_course: course1, created_at: 2.days.ago)
      create(:favorite_golf_course, user: user, golf_course: course2, created_at: 1.day.ago)

      get "/api/v1/favorite_golf_courses", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response[:golf_courses].length).to eq(2)
      # Most recent first
      expect(json_response[:golf_courses][0][:name]).to eq("Second Course")
      expect(json_response[:golf_courses][1][:name]).to eq("First Course")
    end

    it "requires authentication" do
      get "/api/v1/favorite_golf_courses"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/favorite_golf_courses" do
    it "adds course to favorites" do
      expect {
        post "/api/v1/favorite_golf_courses",
             headers: headers,
             params: { golf_course_id: golf_course.id },
             as: :json
      }.to change(FavoriteGolfCourse, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response[:message]).to eq("Course added to favorites")
      expect(json_response[:golf_course][:is_favorite]).to eq(true)
      expect(json_response[:golf_course][:id]).to eq(golf_course.id)
    end

    it "prevents duplicate favorites" do
      create(:favorite_golf_course, user: user, golf_course: golf_course)

      post "/api/v1/favorite_golf_courses",
           headers: headers,
           params: { golf_course_id: golf_course.id },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:error]).to include("already favorited")
    end

    it "returns 404 for invalid course" do
      post "/api/v1/favorite_golf_courses",
           headers: headers,
           params: { golf_course_id: 99999 },
           as: :json

      expect(response).to have_http_status(:not_found)
      expect(json_response[:error]).to eq("Golf course not found")
    end

    it "requires authentication" do
      post "/api/v1/favorite_golf_courses",
           params: { golf_course_id: golf_course.id },
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "includes all course details in response" do
      post "/api/v1/favorite_golf_courses",
           headers: headers,
           params: { golf_course_id: golf_course.id },
           as: :json

      expect(response).to have_http_status(:created)
      course_data = json_response[:golf_course]

      expect(course_data[:id]).to be_present
      expect(course_data[:name]).to eq(golf_course.name)
      expect(course_data[:is_favorite]).to eq(true)
    end
  end

  describe "DELETE /api/v1/favorite_golf_courses/:golf_course_id" do
    it "removes course from favorites" do
      favorite = create(:favorite_golf_course, user: user, golf_course: golf_course)

      expect {
        delete "/api/v1/favorite_golf_courses/#{golf_course.id}", headers: headers
      }.to change(FavoriteGolfCourse, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(json_response[:message]).to eq("Course removed from favorites")
      expect(json_response[:golf_course][:is_favorite]).to eq(false)
    end

    it "returns 404 if course not in favorites" do
      delete "/api/v1/favorite_golf_courses/#{golf_course.id}", headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json_response[:error]).to eq("Course is not in favorites")
    end

    it "returns 404 for invalid course ID" do
      delete "/api/v1/favorite_golf_courses/99999", headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json_response[:error]).to eq("Golf course not found")
    end

    it "requires authentication" do
      delete "/api/v1/favorite_golf_courses/#{golf_course.id}"

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not allow removing another user's favorite" do
      other_user = create(:user)
      favorite = create(:favorite_golf_course, user: other_user, golf_course: golf_course)

      delete "/api/v1/favorite_golf_courses/#{golf_course.id}", headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json_response[:error]).to eq("Course is not in favorites")

      # Verify the other user's favorite still exists
      expect(favorite.reload).to be_present
    end
  end

  private

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end
end
