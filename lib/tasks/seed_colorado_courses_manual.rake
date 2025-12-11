namespace :courses do
  desc "Manually seed popular Colorado Front Range golf courses"
  task seed_colorado_manual: :environment do
    puts "🏌️  Seeding Colorado Front Range golf courses..."
    puts "=" * 60

    courses_data = [
      # Denver Area - Premium Courses
      {
        name: "Fossil Trace Golf Club",
        address: "3050 Illinois St",
        city: "Golden",
        state: "CO",
        zip_code: "80401",
        phone: "(303) 277-8750",
        latitude: 39.7294,
        longitude: -105.2017
      },
      {
        name: "Arrowhead Golf Club",
        address: "10850 Sundown Trail",
        city: "Littleton",
        state: "CO",
        zip_code: "80125",
        phone: "(303) 973-9614",
        latitude: 39.5742,
        longitude: -105.1756
      },
      {
        name: "The Club at Ravenna",
        address: "2500 Paseo Dr",
        city: "Littleton",
        state: "CO",
        zip_code: "80125",
        phone: "(303) 973-2900",
        latitude: 39.5631,
        longitude: -105.1344
      },

      # Denver Public Courses
      {
        name: "City Park Golf Course",
        address: "2500 York St",
        city: "Denver",
        state: "CO",
        zip_code: "80205",
        phone: "(720) 865-0790",
        latitude: 39.7522,
        longitude: -104.9589
      },
      {
        name: "Overland Park Golf Course",
        address: "1801 S Huron St",
        city: "Denver",
        state: "CO",
        zip_code: "80223",
        phone: "(720) 865-0450",
        latitude: 39.6878,
        longitude: -104.9828
      },
      {
        name: "Willis Case Golf Course",
        address: "4999 Vrain St",
        city: "Denver",
        state: "CO",
        zip_code: "80212",
        phone: "(720) 865-0700",
        latitude: 39.7831,
        longitude: -105.0522
      },
      {
        name: "Harvard Gulch Golf Course",
        address: "660 E Iliff Ave",
        city: "Denver",
        state: "CO",
        zip_code: "80210",
        phone: "(720) 865-0450",
        latitude: 39.6722,
        longitude: -104.9800
      },
      {
        name: "Kennedy Golf Course",
        address: "10500 E Hampden Ave",
        city: "Denver",
        state: "CO",
        zip_code: "80231",
        phone: "(720) 865-0420",
        latitude: 39.6539,
        longitude: -104.8703
      },
      {
        name: "Wellshire Golf Course",
        address: "3333 S Colorado Blvd",
        city: "Denver",
        state: "CO",
        zip_code: "80222",
        phone: "(720) 865-0550",
        latitude: 39.6594,
        longitude: -104.9408
      },

      # Aurora Area
      {
        name: "Saddle Rock Golf Course",
        address: "21705 E Arapahoe Rd",
        city: "Aurora",
        state: "CO",
        zip_code: "80016",
        phone: "(303) 699-3939",
        latitude: 39.5906,
        longitude: -104.7544
      },
      {
        name: "Aurora Hills Golf Course",
        address: "500 S Chambers Rd",
        city: "Aurora",
        state: "CO",
        zip_code: "80017",
        phone: "(303) 326-8520",
        latitude: 39.7050,
        longitude: -104.8067
      },
      {
        name: "Springhill Golf Course",
        address: "1100 Telluride St",
        city: "Aurora",
        state: "CO",
        zip_code: "80011",
        phone: "(303) 739-5640",
        latitude: 39.7289,
        longitude: -104.8494
      },

      # Lakewood/Westminster/Arvada Area
      {
        name: "Fox Hollow Golf Course",
        address: "13410 W Morrison Rd",
        city: "Lakewood",
        state: "CO",
        zip_code: "80228",
        phone: "(303) 986-7888",
        latitude: 39.6544,
        longitude: -105.1353
      },
      {
        name: "Homestead Golf Course",
        address: "6650 S Homestead Pkwy",
        city: "Englewood",
        state: "CO",
        zip_code: "80111",
        phone: "(303) 649-3850",
        latitude: 39.5881,
        longitude: -104.9072
      },
      {
        name: "Legacy Ridge Golf Course",
        address: "10801 Legacy Ridge Pkwy",
        city: "Westminster",
        state: "CO",
        zip_code: "80031",
        phone: "(303) 438-8997",
        latitude: 39.8969,
        longitude: -105.0706
      },
      {
        name: "Walnut Creek Golf Preserve",
        address: "8800 W 66th Ave",
        city: "Westminster",
        state: "CO",
        zip_code: "80031",
        phone: "(303) 469-2974",
        latitude: 39.8211,
        longitude: -105.0847
      },
      {
        name: "Indian Tree Golf Club",
        address: "7555 Wadsworth Blvd",
        city: "Arvada",
        state: "CO",
        zip_code: "80003",
        phone: "(303) 403-2570",
        latitude: 39.8319,
        longitude: -105.0814
      },

      # Broomfield/Boulder Area
      {
        name: "Omni Interlocken Golf Club",
        address: "500 Interlocken Blvd",
        city: "Broomfield",
        state: "CO",
        zip_code: "80021",
        phone: "(303) 464-3000",
        latitude: 39.9358,
        longitude: -105.1186
      },
      {
        name: "Flatirons Golf Course",
        address: "5706 E Arapahoe Ave",
        city: "Boulder",
        state: "CO",
        zip_code: "80303",
        phone: "(303) 442-7851",
        latitude: 40.0139,
        longitude: -105.2194
      },
      {
        name: "Lake Valley Golf Club",
        address: "1101 W 88th Ave",
        city: "Boulder",
        state: "CO",
        zip_code: "80021",
        phone: "(303) 444-2114",
        latitude: 39.8606,
        longitude: -105.2831
      },
      {
        name: "Indian Peaks Golf Course",
        address: "2300 Indian Peaks Trail",
        city: "Lafayette",
        state: "CO",
        zip_code: "80026",
        phone: "(303) 666-4706",
        latitude: 39.9839,
        longitude: -105.1186
      },

      # Longmont/Johnstown Area
      {
        name: "Sunset Golf Course",
        address: "1900 Longs Peak Ave",
        city: "Longmont",
        state: "CO",
        zip_code: "80501",
        phone: "(303) 651-8466",
        latitude: 40.1681,
        longitude: -105.0997
      },
      {
        name: "Ute Creek Golf Course",
        address: "1425 S Sunset St",
        city: "Longmont",
        state: "CO",
        zip_code: "80501",
        phone: "(303) 651-8934",
        latitude: 40.1600,
        longitude: -105.1003
      },
      {
        name: "Twin Peaks Golf Course",
        address: "1200 Cornell Dr",
        city: "Longmont",
        state: "CO",
        zip_code: "80503",
        phone: "(303) 772-1722",
        latitude: 40.1636,
        longitude: -105.1253
      },
      {
        name: "Bella Ridge Golf Club",
        address: "2990 Weld County Road 44",
        city: "Johnstown",
        state: "CO",
        zip_code: "80534",
        phone: "(970) 602-4653",
        latitude: 40.3456,
        longitude: -104.9061
      },

      # Brighton Area
      {
        name: "Riverdale Knolls Golf Course",
        address: "13300 Riverdale Rd",
        city: "Brighton",
        state: "CO",
        zip_code: "80602",
        phone: "(303) 659-4700",
        latitude: 39.9628,
        longitude: -104.7789
      },
      {
        name: "Riverdale Dunes Golf Course",
        address: "13300 Riverdale Rd",
        city: "Brighton",
        state: "CO",
        zip_code: "80602",
        phone: "(303) 659-6700",
        latitude: 39.9631,
        longitude: -104.7792
      },

      # Thornton/Northglenn
      {
        name: "Thorncreek Golf Course",
        address: "13555 N Washington St",
        city: "Thornton",
        state: "CO",
        zip_code: "80241",
        phone: "(303) 450-7055",
        latitude: 39.9189,
        longitude: -104.9722
      },
      {
        name: "Todd Creek Golf Club",
        address: "16649 E Lakeside Dr",
        city: "Thornton",
        state: "CO",
        zip_code: "80602",
        phone: "(303) 450-4653",
        latitude: 39.9717,
        longitude: -104.7933
      },

      # Highlands Ranch/Castle Rock
      {
        name: "Highlands Ranch Golf Club",
        address: "9600 S Colorado Blvd",
        city: "Highlands Ranch",
        state: "CO",
        zip_code: "80126",
        phone: "(303) 471-0520",
        latitude: 39.5678,
        longitude: -104.9417
      },
      {
        name: "BackSpin Golf Course",
        address: "9830 Meditech Dr",
        city: "Highlands Ranch",
        state: "CO",
        zip_code: "80126",
        phone: "(303) 791-0350",
        latitude: 39.5611,
        longitude: -104.9322
      }
    ]

    added = 0
    skipped = 0
    errors = 0

    courses_data.each do |course_data|
      begin
        # Check if course already exists
        existing = GolfCourse.find_by(
          name: course_data[:name],
          city: course_data[:city]
        )

        if existing
          puts "⏭️  Skipped: #{course_data[:name]} (already exists)"
          skipped += 1
          next
        end

        # Create the course
        course = GolfCourse.create!(
          name: course_data[:name],
          address: course_data[:address],
          city: course_data[:city],
          state: course_data[:state],
          zip_code: course_data[:zip_code],
          country: "United States",
          phone: course_data[:phone],
          latitude: course_data[:latitude],
          longitude: course_data[:longitude]
        )

        puts "✅ Added: #{course.name} (#{course.city}, #{course.state})"
        added += 1

      rescue StandardError => e
        puts "❌ Error adding #{course_data[:name]}: #{e.message}"
        errors += 1
      end
    end

    puts "\n" + "=" * 60
    puts "🏁 Seeding complete!"
    puts "   ✅ Added: #{added} courses"
    puts "   ⏭️  Skipped: #{skipped} courses (duplicates)"
    puts "   ❌ Errors: #{errors}"
    puts "=" * 60
  end
end
