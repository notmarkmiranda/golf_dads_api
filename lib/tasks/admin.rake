namespace :admin do
  desc "Make a user an admin by email"
  task :promote, [:email] => :environment do |t, args|
    if args[:email].blank?
      puts "Usage: rails admin:promote[user@example.com]"
      exit 1
    end

    user = User.find_by(email_address: args[:email])

    if user.nil?
      puts "Error: User with email '#{args[:email]}' not found."
      exit 1
    end

    if user.admin?
      puts "User '#{user.email_address}' is already an admin."
    else
      user.update!(admin: true)
      puts "Successfully promoted '#{user.email_address}' to admin."
    end
  end

  desc "Remove admin privileges from a user by email"
  task :demote, [:email] => :environment do |t, args|
    if args[:email].blank?
      puts "Usage: rails admin:demote[user@example.com]"
      exit 1
    end

    user = User.find_by(email_address: args[:email])

    if user.nil?
      puts "Error: User with email '#{args[:email]}' not found."
      exit 1
    end

    if !user.admin?
      puts "User '#{user.email_address}' is not an admin."
    else
      user.update!(admin: false)
      puts "Successfully removed admin privileges from '#{user.email_address}'."
    end
  end

  desc "List all admin users"
  task list: :environment do
    admins = User.where(admin: true)

    if admins.empty?
      puts "No admin users found."
    else
      puts "Admin users:"
      admins.each do |admin|
        puts "  - #{admin.email_address} (ID: #{admin.id})"
      end
    end
  end
end
