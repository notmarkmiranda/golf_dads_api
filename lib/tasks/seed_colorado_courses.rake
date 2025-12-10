namespace :courses do
  desc "Seed golf courses from Denver/Boulder/Longmont area"
  task seed_colorado: :environment do
    # Use GolfCourseApiService to handle API calls
    api_service = GolfCourseApiService.new

    # Target cities/areas in the greater Denver/Boulder/Longmont region
    search_terms = [
      "Denver Colorado",
      "Boulder Colorado",
      "Longmont Colorado",
      "Aurora Colorado",
      "Lakewood Colorado",
      "Arvada Colorado",
      "Westminster Colorado",
      "Thornton Colorado",
      "Broomfield Colorado",
      "Louisville Colorado",
      "Lafayette Colorado",
      "Erie Colorado",
      "Superior Colorado",
      "Golden Colorado",
      "Highlands Ranch Colorado",
      "Littleton Colorado"
    ]

    total_added = 0
    total_skipped = 0
    total_errors = 0

    puts "🏌️  Seeding golf courses from Colorado Front Range..."
    puts "=" * 60

    search_terms.each do |search_term|
      puts "\n📍 Searching: #{search_term}..."

      begin
        # Use the service's search method
        courses = api_service.search(query: search_term, limit: 50)

        puts "   Found #{courses.length} courses"

        courses.each do |course_data|
          # Skip if no name
          next unless course_data[:name].present?

          # Check if course already exists by external_id or name+city
          existing = if course_data[:external_id].present?
            GolfCourse.find_by(external_api_id: course_data[:external_id])
          else
            GolfCourse.find_by(
              name: course_data[:name],
              city: course_data[:city]
            )
          end

          if existing
            puts "   ⏭️  Skipped: #{course_data[:name]} (already exists)"
            total_skipped += 1
            next
          end

          # Use the service's find_or_create method
          golf_course = api_service.find_or_create_course(course_data: course_data)

          if golf_course
            puts "   ✅ Added: #{golf_course.name}"
            total_added += 1
          else
            puts "   ❌ Failed to create: #{course_data[:name]}"
            total_errors += 1
          end

          # Rate limiting - be nice to the API
          sleep 1
        end

      rescue StandardError => e
        puts "   ❌ Error: #{e.message}"
        total_errors += 1
      end

      # Rate limiting between searches
      sleep 1
    end

    puts "\n" + "=" * 60
    puts "🏁 Seeding complete!"
    puts "   ✅ Added: #{total_added} courses"
    puts "   ⏭️  Skipped: #{total_skipped} courses (duplicates)"
    puts "   ❌ Errors: #{total_errors}"
    puts "=" * 60
  end

  desc "Seed golf courses from a specific city"
  task :seed_city, [:city, :state, :zip] => :environment do |t, args|
    require 'net/http'
    require 'json'

    unless args[:city] && args[:state] && args[:zip]
      puts "Usage: rake courses:seed_city[City,ST,12345]"
      puts "Example: rake courses:seed_city[Denver,CO,80202]"
      exit 1
    end

    # Check for API key in ENV or Rails credentials
    api_key = ENV['GOLF_COURSE_API_KEY'] || Rails.application.credentials.golf_course_api_key

    unless api_key
      puts "❌ Error: GOLF_COURSE_API_KEY not found"
      puts "   Please add it to .env file or Rails credentials"
      exit 1
    end

    puts "🏌️  Searching #{args[:city]}, #{args[:state]} (#{args[:zip]})..."

    uri = URI("https://api.golfcourseapi.com/courses")
    params = {
      key: api_key,
      zip: args[:zip],
      radius: 15
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)

    unless response.is_a?(Net::HTTPSuccess)
      puts "❌ API error: #{response.code} #{response.message}"
      exit 1
    end

    data = JSON.parse(response.body)
    courses = data['courses'] || []

    puts "Found #{courses.length} courses\n"

    added = 0
    skipped = 0

    courses.each do |course_data|
      existing = GolfCourse.find_by(
        name: course_data['name'],
        city: course_data['city']
      )

      if existing
        puts "⏭️  Skipped: #{course_data['name']} (already exists)"
        skipped += 1
        next
      end

      golf_course = GolfCourse.create!(
        name: course_data['name'],
        club_name: course_data['club_name'],
        address: course_data['address'],
        city: course_data['city'],
        state: course_data['state'],
        zip_code: course_data['zip_code'],
        country: course_data['country'] || 'United States',
        latitude: course_data['latitude']&.to_f,
        longitude: course_data['longitude']&.to_f
      )

      puts "✅ Added: #{golf_course.name}"
      added += 1

      sleep 0.5
    end

    puts "\n✅ Added #{added} courses, skipped #{skipped} duplicates"
  end
end
