class GolfCourseApiService
  include HTTParty
  base_uri "https://api.golfcourseapi.com"

  # Initialize with API key from Rails credentials or ENV
  def initialize(api_key: nil)
    @api_key = api_key ||
               Rails.application.credentials.dig(:golf_course_api, :key) ||
               ENV["GOLF_COURSE_API_KEY"]

    if @api_key.blank?
      raise ArgumentError, "Golf Course API key not found. Please set it in Rails credentials or ENV['GOLF_COURSE_API_KEY']"
    end

    @options = {
      headers: {
        "Authorization" => "Key #{@api_key}",
        "Accept" => "application/json"
      },
      timeout: 10
    }
  end

  # Search for courses by name
  # Returns array of course hashes with standardized format
  def search(query:, limit: 20)
    return [] if query.blank?

    response = self.class.get(
      "/v1/search",
      @options.merge(query: { search_query: query })
    )

    if response.success?
      parse_courses(response.parsed_response)
    else
      Rails.logger.error("Golf Course API error: #{response.code} - #{response.message}")
      []
    end
  rescue HTTParty::Error, Timeout::Error, StandardError => e
    Rails.logger.error("Golf Course API request failed: #{e.message}")
    []
  end

  # Get course details by external API ID
  def get_course(external_id:)
    response = self.class.get(
      "/v1/courses/#{external_id}",
      @options
    )

    if response.success?
      parse_course(response.parsed_response)
    else
      Rails.logger.error("Golf Course API error: #{response.code} - #{response.message}")
      nil
    end
  rescue HTTParty::Error, Timeout::Error, StandardError => e
    Rails.logger.error("Golf Course API request failed: #{e.message}")
    nil
  end

  # Find or create golf course from course data hash
  # This caches courses locally as they're discovered
  # Also handles manual entries without external_id
  def find_or_create_course(course_data:)
    external_id = course_data[:external_id]

    # If external_id exists, check for existing course
    if external_id.present?
      course = GolfCourse.find_by(external_api_id: external_id)
      return course if course
    end

    # Create new course (either from API or manual entry)
    GolfCourse.create!(
      name: course_data[:name],
      club_name: course_data[:club_name],
      address: course_data[:address],
      city: course_data[:city],
      state: course_data[:state],
      zip_code: course_data[:zip_code],
      country: course_data[:country],
      latitude: course_data[:latitude],
      longitude: course_data[:longitude],
      external_api_id: external_id,
      phone: course_data[:phone],
      website: course_data[:website],
      description: course_data[:description]
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to create golf course: #{e.message}")
    nil
  end

  private

  def parse_courses(data)
    courses = data.is_a?(Hash) && data["courses"] ? data["courses"] : []

    # Parse and deduplicate by external_id
    parsed = courses.map { |c| parse_course(c) }.compact
    parsed.uniq { |c| c[:external_id] }
  end

  def parse_course(course_data)
    return nil unless course_data

    location = course_data["location"] || {}

    {
      external_id: course_data["id"],
      name: course_data["course_name"] || course_data["name"],
      club_name: course_data["club_name"],
      address: location["address"],
      city: location["city"],
      state: location["state"],
      zip_code: location["zip_code"],
      country: location["country"],
      latitude: location["latitude"]&.to_f,
      longitude: location["longitude"]&.to_f,
      phone: course_data["phone"],
      website: course_data["website"],
      description: course_data["description"]
    }
  end
end
