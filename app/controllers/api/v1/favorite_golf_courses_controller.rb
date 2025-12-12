module Api
  module V1
    class FavoriteGolfCoursesController < Api::BaseController
      before_action :require_authentication
      before_action :set_golf_course, only: [:create, :destroy]

      # GET /api/v1/favorite_golf_courses
      def index
        favorites = current_user.favorites

        render json: {
          golf_courses: favorites.map { |course| course_json(course, is_favorite: true) }
        }, status: :ok
      end

      # POST /api/v1/favorite_golf_courses
      # Body: { golf_course_id: 123 }
      def create
        favorite = current_user.favorite_golf_courses.build(golf_course: @golf_course)

        if favorite.save
          render json: {
            golf_course: course_json(@golf_course, is_favorite: true),
            message: "Course added to favorites"
          }, status: :created
        else
          render json: { error: favorite.errors.full_messages.first }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/favorite_golf_courses/:golf_course_id
      def destroy
        favorite = current_user.favorite_golf_courses.find_by(golf_course: @golf_course)

        if favorite
          favorite.destroy
          render json: {
            golf_course: course_json(@golf_course, is_favorite: false),
            message: "Course removed from favorites"
          }, status: :ok
        else
          render json: { error: "Course is not in favorites" }, status: :not_found
        end
      end

      private

      def set_golf_course
        @golf_course = GolfCourse.find(params[:golf_course_id] || params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Golf course not found" }, status: :not_found
      end

      def course_json(course, is_favorite: false)
        {
          id: course.id,
          external_id: course.external_api_id,
          name: course.name,
          club_name: course.club_name,
          address: course.address,
          city: course.city,
          state: course.state,
          zip_code: course.zip_code,
          country: course.country,
          latitude: course.latitude&.to_f,
          longitude: course.longitude&.to_f,
          phone: course.phone,
          website: course.website,
          is_favorite: is_favorite
        }
      end
    end
  end
end
