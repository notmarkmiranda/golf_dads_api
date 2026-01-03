# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Clear existing data in development
if Rails.env.development?
  puts "🧹 Cleaning development database..."
  Reservation.destroy_all
  ActiveRecord::Base.connection.execute("DELETE FROM groups_tee_time_postings")
  TeeTimePosting.destroy_all
  GolfCourse.destroy_all
  GroupMembership.destroy_all
  Group.destroy_all
  User.destroy_all
end

# Create admin user
puts "👤 Creating or finding admin user..."
admin = User.find_or_create_by!(email_address: 'notmarkmiranda@gmail.com') do |user|
  user.name = 'Admin User'
  user.password = 'password1234'
  user.password_confirmation = 'password1234'
  user.admin = true
end
puts "✅ Admin user ready: #{admin.email_address}"

# Create regular users
puts "👥 Creating or finding regular users..."
users = []

users << User.find_or_create_by!(email_address: 'john@example.com') do |user|
  user.name = 'John Smith'
  user.password = 'password1234'
  user.password_confirmation = 'password1234'
end

users << User.find_or_create_by!(email_address: 'jane@example.com') do |user|
  user.name = 'Jane Doe'
  user.password = 'password1234'
  user.password_confirmation = 'password1234'
end

users << User.find_or_create_by!(email_address: 'mike@example.com') do |user|
  user.name = 'Mike Johnson'
  user.password = 'password1234'
  user.password_confirmation = 'password1234'
end

users << User.find_or_create_by!(email_address: 'sarah@example.com') do |user|
  user.name = 'Sarah Williams'
  user.password = 'password1234'
  user.password_confirmation = 'password1234'
end

puts "✅ Users ready: #{users.count} regular users"

# Create groups
puts "👨‍👩‍👧‍👦 Creating or finding groups..."
groups = []

# John's groups
weekend_warriors = Group.find_or_create_by!(name: 'Weekend Warriors', owner: users[0]) do |group|
  group.description = 'Saturday morning golf group'
end
groups << weekend_warriors

early_birds = Group.find_or_create_by!(name: 'Early Birds', owner: users[0]) do |group|
  group.description = 'We tee off before 7am!'
end
groups << early_birds

# Jane's groups
ladies_league = Group.find_or_create_by!(name: 'Ladies League', owner: users[1]) do |group|
  group.description = 'Weekly ladies golf group'
end
groups << ladies_league

# Mike's groups
corporate_crew = Group.find_or_create_by!(name: 'Corporate Crew', owner: users[2]) do |group|
  group.description = 'After-work golf rounds'
end
groups << corporate_crew

puts "✅ Groups ready: #{groups.count} groups"

# Add group members
puts "🤝 Adding group members..."
memberships = []

# Weekend Warriors members (John's group)
memberships << GroupMembership.find_or_create_by!(user: users[1], group: weekend_warriors) # Jane joins
memberships << GroupMembership.find_or_create_by!(user: users[2], group: weekend_warriors) # Mike joins

# Ladies League members (Jane's group)
memberships << GroupMembership.find_or_create_by!(user: users[3], group: ladies_league) # Sarah joins

# Corporate Crew members (Mike's group)
memberships << GroupMembership.find_or_create_by!(user: users[0], group: corporate_crew) # John joins
memberships << GroupMembership.find_or_create_by!(user: users[3], group: corporate_crew) # Sarah joins

puts "✅ Memberships ready: #{memberships.count} group memberships"

# Create golf courses with real location data
puts "🏌️ Creating golf courses..."
golf_courses = {}

golf_courses[:pebble_beach] = GolfCourse.find_or_create_by!(name: 'Pebble Beach Golf Links') do |course|
  course.club_name = 'Pebble Beach Company'
  course.address = '1700 17 Mile Dr'
  course.city = 'Pebble Beach'
  course.state = 'CA'
  course.zip_code = '93953'
  course.country = 'USA'
  course.latitude = 36.5674
  course.longitude = -121.9500
  course.phone = '(831) 622-8239'
  course.website = 'https://www.pebblebeach.com'
end

golf_courses[:torrey_pines] = GolfCourse.find_or_create_by!(name: 'Torrey Pines Golf Course') do |course|
  course.club_name = 'Torrey Pines Municipal Golf Course'
  course.address = '11480 N Torrey Pines Rd'
  course.city = 'La Jolla'
  course.state = 'CA'
  course.zip_code = '92037'
  course.country = 'USA'
  course.latitude = 32.9043
  course.longitude = -117.2445
  course.phone = '(858) 452-3226'
  course.website = 'https://www.sandiego.gov/park-and-recreation/golf/torreypines'
end

golf_courses[:augusta] = GolfCourse.find_or_create_by!(name: 'Augusta National Golf Club') do |course|
  course.club_name = 'Augusta National Golf Club'
  course.address = '2604 Washington Rd'
  course.city = 'Augusta'
  course.state = 'GA'
  course.zip_code = '30904'
  course.country = 'USA'
  course.latitude = 33.5027
  course.longitude = -82.0201
  course.phone = '(706) 667-6000'
  course.website = 'https://www.masters.com'
end

golf_courses[:st_andrews] = GolfCourse.find_or_create_by!(name: 'St Andrews Links - Old Course') do |course|
  course.club_name = 'St Andrews Links Trust'
  course.address = 'West Sands Rd'
  course.city = 'St Andrews'
  course.state = 'Scotland'
  course.zip_code = 'KY16 9SF'
  course.country = 'United Kingdom'
  course.latitude = 56.3446
  course.longitude = -2.8154
  course.phone = '+44 1334 466666'
  course.website = 'https://www.standrews.com'
end

golf_courses[:pinehurst] = GolfCourse.find_or_create_by!(name: 'Pinehurst Resort - Course No. 2') do |course|
  course.club_name = 'Pinehurst Resort'
  course.address = '80 Carolina Vista Dr'
  course.city = 'Pinehurst'
  course.state = 'NC'
  course.zip_code = '28374'
  course.country = 'USA'
  course.latitude = 35.1955
  course.longitude = -79.4717
  course.phone = '(855) 235-8507'
  course.website = 'https://www.pinehurst.com'
end

golf_courses[:bethpage] = GolfCourse.find_or_create_by!(name: 'Bethpage State Park - Black Course') do |course|
  course.club_name = 'Bethpage State Park'
  course.address = '99 Quaker Meeting House Rd'
  course.city = 'Farmingdale'
  course.state = 'NY'
  course.zip_code = '11735'
  course.country = 'USA'
  course.latitude = 40.7446
  course.longitude = -73.4577
  course.phone = '(516) 249-0700'
  course.website = 'https://www.nysparks.com/golf-courses/27/details.aspx'
end

golf_courses[:spyglass] = GolfCourse.find_or_create_by!(name: 'Spyglass Hill Golf Course') do |course|
  course.club_name = 'Pebble Beach Company'
  course.address = '1700 17 Mile Dr'
  course.city = 'Pebble Beach'
  course.state = 'CA'
  course.zip_code = '93953'
  course.country = 'USA'
  course.latitude = 36.5857
  course.longitude = -121.9397
  course.phone = '(800) 654-9300'
  course.website = 'https://www.pebblebeach.com/golf/spyglass-hill-golf-course'
end

golf_courses[:cypress_point] = GolfCourse.find_or_create_by!(name: 'Cypress Point Club') do |course|
  course.club_name = 'Cypress Point Club'
  course.address = '3150 17 Mile Dr'
  course.city = 'Pebble Beach'
  course.state = 'CA'
  course.zip_code = '93953'
  course.country = 'USA'
  course.latitude = 36.5847
  course.longitude = -121.9619
  course.phone = '(831) 624-2223'
  course.website = 'https://www.cypresspoint.com'
end

puts "✅ Created #{golf_courses.count} golf courses"

# Create tee time postings (skip if already exist to avoid time-sensitive issues)
if TeeTimePosting.count == 0 || Rails.env.development?
puts "⛳ Creating tee time postings..."
postings = []

# All tee times must be associated with groups (no public postings)

# Weekend Warriors postings
posting_1 = TeeTimePosting.create!(
  user: users[0],
  tee_time: 10.days.from_now.change(hour: 7, min: 0),
  golf_course: golf_courses[:pebble_beach],
  course_name: 'Pebble Beach Golf Links',
  available_spots: 2,
  total_spots: 4,
  notes: 'Weekend Warriors - early morning at Pebble Beach!'
)
posting_1.groups << weekend_warriors
postings << posting_1

posting_2 = TeeTimePosting.create!(
  user: users[0],
  tee_time: 2.weeks.from_now.change(hour: 8, min: 0),
  golf_course: golf_courses[:spyglass],
  course_name: 'Spyglass Hill Golf Course',
  available_spots: 3,
  total_spots: 4,
  notes: 'Beautiful Pebble Beach area course'
)
posting_2.groups << weekend_warriors
postings << posting_2

posting_3 = TeeTimePosting.create!(
  user: users[1],
  tee_time: 2.weeks.from_now.change(hour: 13, min: 0),
  golf_course: golf_courses[:torrey_pines],
  course_name: 'Torrey Pines Golf Course',
  available_spots: 2,
  total_spots: 4,
  notes: 'Afternoon round - ocean views!'
)
posting_3.groups << weekend_warriors
postings << posting_3

# Ladies League postings
posting_4 = TeeTimePosting.create!(
  user: users[1],
  tee_time: 3.weeks.from_now.change(hour: 8, min: 0),
  golf_course: golf_courses[:augusta],
  course_name: 'Augusta National Golf Club',
  available_spots: 2,
  total_spots: 4,
  notes: 'Ladies League - Augusta practice round'
)
posting_4.groups << ladies_league
postings << posting_4

posting_5 = TeeTimePosting.create!(
  user: users[3],
  tee_time: 3.weeks.from_now.change(hour: 9, min: 30),
  golf_course: golf_courses[:pinehurst],
  course_name: 'Pinehurst Resort - Course No. 2',
  available_spots: 2,
  total_spots: 4,
  notes: 'Classic Donald Ross design'
)
posting_5.groups << ladies_league
postings << posting_5

# Corporate Crew postings
posting_6 = TeeTimePosting.create!(
  user: users[2],
  tee_time: 3.weeks.from_now.change(hour: 17, min: 0),
  golf_course: golf_courses[:bethpage],
  course_name: 'Bethpage State Park - Black Course',
  available_spots: 2,
  total_spots: 4,
  notes: 'Corporate Crew - after-work challenge!'
)
posting_6.groups << corporate_crew
postings << posting_6

posting_7 = TeeTimePosting.create!(
  user: users[0],
  tee_time: 10.days.from_now.change(hour: 17, min: 30),
  golf_course: golf_courses[:torrey_pines],
  course_name: 'Torrey Pines Golf Course',
  available_spots: 1,
  total_spots: 4,
  notes: 'Twilight round at Torrey Pines'
)
posting_7.groups << corporate_crew
postings << posting_7

# Early Birds postings
posting_8 = TeeTimePosting.create!(
  user: users[0],
  tee_time: 12.days.from_now.change(hour: 6, min: 30),
  golf_course: golf_courses[:pebble_beach],
  course_name: 'Pebble Beach Golf Links',
  available_spots: 3,
  total_spots: 4,
  notes: 'Early Birds - sunrise round!'
)
posting_8.groups << early_birds
postings << posting_8

# Past posting (for testing) - skip validations since it's in the past
past_posting = TeeTimePosting.new(
  user: users[0],
  tee_time: 2.days.ago.change(hour: 8, min: 0),
  golf_course: golf_courses[:cypress_point],
  course_name: 'Cypress Point Club',
  available_spots: 0,
  total_spots: 4,
  notes: 'Already played - keeping for history'
)
past_posting.save(validate: false)
postings << past_posting

puts "✅ Created #{postings.count} tee time postings"

# Create reservations
puts "📋 Creating reservations..."
reservations = []

# Reservations on Weekend Warriors postings
reservations << Reservation.create!(
  user: users[2], # Mike reserves
  tee_time_posting: postings[0], # John's Pebble Beach posting
  spots_reserved: 1
)

reservations << Reservation.create!(
  user: users[1], # Jane reserves
  tee_time_posting: postings[1], # John's Spyglass posting
  spots_reserved: 1
)

# Reservations on Ladies League postings
reservations << Reservation.create!(
  user: users[3], # Sarah reserves
  tee_time_posting: postings[3], # Jane's Augusta posting
  spots_reserved: 1
)

# Reservations on Corporate Crew postings
reservations << Reservation.create!(
  user: users[0], # John reserves
  tee_time_posting: postings[5], # Mike's Bethpage posting
  spots_reserved: 1
)

reservations << Reservation.create!(
  user: users[3], # Sarah reserves
  tee_time_posting: postings[6], # John's Torrey Pines posting
  spots_reserved: 1
)

puts "✅ Created #{reservations.count} reservations"
else
  puts "⏩ Skipping tee time postings and reservations (already exist in production)"
end

# Summary
puts "\n✨ Seed data created successfully! ✨"
puts "=" * 50
puts "👤 Users: #{User.count} (#{User.where(admin: true).count} admin)"
puts "👨‍👩‍👧‍👦 Groups: #{Group.count}"
puts "🤝 Group Memberships: #{GroupMembership.count}"
puts "🏌️ Golf Courses: #{GolfCourse.count}"
puts "⛳ Tee Time Postings: #{TeeTimePosting.count} (all group-based, no public postings)"
postings_with_location = TeeTimePosting.joins(:golf_course).where.not(golf_courses: { latitude: nil, longitude: nil }).count
puts "   📍 With location data: #{postings_with_location} (#{((postings_with_location.to_f / TeeTimePosting.count) * 100).round}%)"
puts "📋 Reservations: #{Reservation.count}"
puts "=" * 50
puts "\n📝 Test Credentials:"
puts "Admin: notmarkmiranda@gmail.com / password1234"
puts "Users: john@example.com, jane@example.com, mike@example.com, sarah@example.com"
puts "Password for all users: password1234"
puts "\n🎯 Group Structure:"
puts "• Weekend Warriors (John) - Members: Jane, Mike"
puts "• Early Birds (John) - Solo"
puts "• Ladies League (Jane) - Members: Sarah"
puts "• Corporate Crew (Mike) - Members: John, Sarah"
puts "\n🚀 Ready to test the API!"
puts "\n📍 Location Features:"
puts "• All tee times have golf course associations with coordinates"
puts "• Try nearby filtering: GET /api/v1/tee_time_postings?latitude=36.5&longitude=-121.9&radius=25"
puts "• Courses span multiple locations: CA (4), GA (1), NC (1), NY (1), Scotland (1)"
