namespace :courses do
  desc "Geocode golf courses missing coordinates"
  task geocode_missing: :environment do
    # Find courses with address info but no coordinates
    courses = GolfCourse.where(latitude: nil, longitude: nil)
                       .where.not(address: nil)
                       .or(GolfCourse.where(latitude: nil, longitude: nil).where.not(city: nil))

    puts "Found #{courses.count} courses to geocode"

    success_count = 0
    failure_count = 0

    courses.find_each do |course|
      # Check if course has any address info
      next unless course.send(:full_address).present?

      print "Geocoding #{course.name}... "

      # Save triggers the after_validation callback
      if course.save
        if course.latitude && course.longitude
          puts "✓ (#{course.latitude}, #{course.longitude})"
          success_count += 1
        else
          puts "✗ (no results)"
          failure_count += 1
        end
      else
        puts "✗ (validation failed)"
        failure_count += 1
      end

      # Rate limiting for Nominatim (1 req/sec max)
      sleep 1
    end

    puts "\nGeocoding complete:"
    puts "  ✓ Success: #{success_count}"
    puts "  ✗ Failed: #{failure_count}"
  end
end
