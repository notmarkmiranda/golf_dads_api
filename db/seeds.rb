# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Clear existing data in development
if Rails.env.development?
  puts "🧹 Cleaning development database..."
  Reservation.destroy_all
  TeeTimePosting.destroy_all
  GroupMembership.destroy_all
  Group.destroy_all
  User.destroy_all
end

# Create admin user
puts "👤 Creating admin user..."
admin = User.create!(
  email_address: 'notmarkmiranda@gmail.com',
  name: 'Admin User',
  password: 'password1234',
  password_confirmation: 'password1234',
  admin: true
)
puts "✅ Admin user created: #{admin.email_address}"

# Create regular users
puts "👥 Creating regular users..."
users = []

users << User.create!(
  email_address: 'john@example.com',
  name: 'John Smith',
  password: 'password1234',
  password_confirmation: 'password1234'
)

users << User.create!(
  email_address: 'jane@example.com',
  name: 'Jane Doe',
  password: 'password1234',
  password_confirmation: 'password1234'
)

users << User.create!(
  email_address: 'mike@example.com',
  name: 'Mike Johnson',
  password: 'password1234',
  password_confirmation: 'password1234'
)

users << User.create!(
  email_address: 'sarah@example.com',
  name: 'Sarah Williams',
  password: 'password1234',
  password_confirmation: 'password1234'
)

puts "✅ Created #{users.count} regular users"

# Create groups
puts "👨‍👩‍👧‍👦 Creating groups..."
groups = []

# John's groups
weekend_warriors = users[0].owned_groups.create!(
  name: 'Weekend Warriors',
  description: 'Saturday morning golf group'
)
groups << weekend_warriors

early_birds = users[0].owned_groups.create!(
  name: 'Early Birds',
  description: 'We tee off before 7am!'
)
groups << early_birds

# Jane's groups
ladies_league = users[1].owned_groups.create!(
  name: 'Ladies League',
  description: 'Weekly ladies golf group'
)
groups << ladies_league

# Mike's groups
corporate_crew = users[2].owned_groups.create!(
  name: 'Corporate Crew',
  description: 'After-work golf rounds'
)
groups << corporate_crew

puts "✅ Created #{groups.count} groups"

# Add group members
puts "🤝 Adding group members..."
memberships = []

# Weekend Warriors members (John's group)
memberships << GroupMembership.create!(user: users[1], group: weekend_warriors) # Jane joins
memberships << GroupMembership.create!(user: users[2], group: weekend_warriors) # Mike joins

# Ladies League members (Jane's group)
memberships << GroupMembership.create!(user: users[3], group: ladies_league) # Sarah joins

# Corporate Crew members (Mike's group)
memberships << GroupMembership.create!(user: users[0], group: corporate_crew) # John joins
memberships << GroupMembership.create!(user: users[3], group: corporate_crew) # Sarah joins

puts "✅ Created #{memberships.count} group memberships"

# Create tee time postings
puts "⛳ Creating tee time postings..."
postings = []

# Public postings (visible to everyone)
postings << TeeTimePosting.create!(
  user: users[0],
  tee_time: 2.days.from_now.change(hour: 8, min: 0),
  course_name: 'Pebble Beach Golf Links',
  available_spots: 2,
  total_spots: 4,
  notes: 'Looking for 2 more players for an early morning round!'
)

postings << TeeTimePosting.create!(
  user: users[1],
  tee_time: 3.days.from_now.change(hour: 10, min: 30),
  course_name: 'Augusta National Golf Club',
  available_spots: 1,
  total_spots: 4,
  notes: 'Need 1 more! Experienced players preferred.'
)

postings << TeeTimePosting.create!(
  user: users[2],
  tee_time: 5.days.from_now.change(hour: 14, min: 0),
  course_name: 'St Andrews Links',
  available_spots: 3,
  total_spots: 4,
  notes: 'Afternoon round, all skill levels welcome'
)

# Group postings (visible only to group members)
postings << TeeTimePosting.create!(
  user: users[0],
  group: weekend_warriors,
  tee_time: 7.days.from_now.change(hour: 7, min: 0),
  course_name: 'Torrey Pines Golf Course',
  available_spots: 2,
  total_spots: 4,
  notes: 'Weekend Warriors - our regular Saturday game!'
)

postings << TeeTimePosting.create!(
  user: users[1],
  group: ladies_league,
  tee_time: 4.days.from_now.change(hour: 9, min: 0),
  course_name: 'Pinehurst Resort',
  available_spots: 1,
  total_spots: 4,
  notes: 'Ladies League tournament prep round'
)

postings << TeeTimePosting.create!(
  user: users[2],
  group: corporate_crew,
  tee_time: 6.days.from_now.change(hour: 17, min: 0),
  course_name: 'Bethpage Black Course',
  available_spots: 2,
  total_spots: 4,
  notes: 'After-work round, bring your A-game!'
)

# Past posting (for testing) - skip validations since it's in the past
past_posting = TeeTimePosting.new(
  user: users[0],
  tee_time: 2.days.ago.change(hour: 8, min: 0),
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

# Reservations on public postings
reservations << Reservation.create!(
  user: users[2], # Mike reserves
  tee_time_posting: postings[0], # John's Pebble Beach posting
  spots_reserved: 1
)

reservations << Reservation.create!(
  user: users[3], # Sarah reserves
  tee_time_posting: postings[1], # Jane's Augusta posting
  spots_reserved: 1
)

# Reservations on group postings
reservations << Reservation.create!(
  user: users[1], # Jane reserves
  tee_time_posting: postings[3], # John's Weekend Warriors posting
  spots_reserved: 1
)

reservations << Reservation.create!(
  user: users[3], # Sarah reserves
  tee_time_posting: postings[4], # Jane's Ladies League posting
  spots_reserved: 1
)

puts "✅ Created #{reservations.count} reservations"

# Summary
puts "\n✨ Seed data created successfully! ✨"
puts "=" * 50
puts "👤 Users: #{User.count} (#{User.where(admin: true).count} admin)"
puts "👨‍👩‍👧‍👦 Groups: #{Group.count}"
puts "🤝 Group Memberships: #{GroupMembership.count}"
puts "⛳ Tee Time Postings: #{TeeTimePosting.count} (#{TeeTimePosting.where(group_id: nil).count} public, #{TeeTimePosting.where.not(group_id: nil).count} group)"
puts "📋 Reservations: #{Reservation.count}"
puts "=" * 50
puts "\n📝 Test Credentials:"
puts "Admin: notmarkmiranda@gmail.com / password1234"
puts "Users: john@example.com, jane@example.com, mike@example.com, sarah@example.com"
puts "Password for all users: password1234"
puts "\n🚀 Ready to test the API!"
