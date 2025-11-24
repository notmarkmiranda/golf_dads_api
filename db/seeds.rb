# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create admin user
admin = User.find_or_initialize_by(email_address: 'notmarkmiranda@gmail.com')
admin.assign_attributes(
  name: 'Admin User',
  password: 'password1234',
  password_confirmation: 'password1234',
  admin: true
)
admin.save!

puts "✅ Admin user created: #{admin.email_address}"
