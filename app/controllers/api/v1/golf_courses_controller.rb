module Api
  module V1
    class GolfCoursesController < Api::BaseController
      # GET /api/v1/golf_courses/search?query=pebble
      # Search for golf courses by name (searches local DB + external API)
      def search
        query = params[:query]

        if query.blank?
          render json: { error: 'Query parameter required' }, status: :bad_request
          return
        end

        # Search local database first
        local_courses = GolfCourse.where('name ILIKE ?', "%#{query}%")
                                   .limit(10)
                                   .map { |c| course_json(c) }

        # Search external API
        api_service = GolfCourseApiService.new
        api_courses = api_service.search(query: query, limit: 10)

        # Combine and deduplicate (prefer local records)
        all_courses = (local_courses + api_courses).uniq { |c| c[:external_id] || c[:id] }

        render json: { golf_courses: all_courses }, status: :ok
      end

      # GET /api/v1/golf_courses/nearby?latitude=36.5&longitude=-121.9&radius=25
      # Find golf courses near a location
      def nearby
        latitude = params[:latitude]&.to_f
        longitude = params[:longitude]&.to_f
        radius = params[:radius]&.to_i || current_user.preferred_radius_miles || 25

        unless latitude && longitude
          render json: { error: 'Latitude and longitude required' }, status: :bad_request
          return
        end

        courses = GolfCourse.near(
          latitude: latitude,
          longitude: longitude,
          radius_miles: radius
        ).limit(50).map { |c| course_json(c, latitude: latitude, longitude: longitude) }

        render json: { golf_courses: courses }, status: :ok
      end

      # POST /api/v1/golf_courses/cache
      # Cache a golf course from search results to local database
      def cache
        course_data = params[:golf_course]

        if course_data.blank?
          render json: { error: 'Golf course data required' }, status: :bad_request
          return
        end

        # Convert string keys to symbols for the service
        course_hash = course_data.to_unsafe_h.symbolize_keys

        api_service = GolfCourseApiService.new
        course = api_service.find_or_create_course(course_data: course_hash)

        if course
          render json: { golf_course: course_json(course) }, status: :created
        else
          render json: { error: 'Failed to cache course' }, status: :unprocessable_entity
        end
      end

      private

      def course_json(course, latitude: nil, longitude: nil)
        result = {
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
          website: course.website
        }

        # Include distance if coordinates provided and course has location
        if latitude && longitude && course.respond_to?(:distance_miles)
          result[:distance_miles] = course.distance_miles&.to_f&.round(1)
        elsif latitude && longitude && course.latitude && course.longitude
          result[:distance_miles] = course.distance_to(
            latitude: latitude,
            longitude: longitude
          )&.round(1)
        end

        result
      end
    end
  end
end
