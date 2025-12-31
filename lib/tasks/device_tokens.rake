namespace :device_tokens do
  desc 'Clean up duplicate device tokens - keep only most recently used token per user/platform'
  task cleanup: :environment do
    puts "Starting device token cleanup..."
    puts "=" * 80

    deleted_count = 0
    user_count = 0

    # Get all user IDs with device tokens
    user_ids = DeviceToken.distinct.pluck(:user_id)

    puts "Found #{user_ids.count} users with device tokens"

    user_ids.each do |user_id|
      user = User.find(user_id)

      # Process each platform separately
      %w[ios android].each do |platform|
        tokens = user.device_tokens.where(platform: platform).order(last_used_at: :desc)

        next if tokens.count <= 1 # Skip if user only has 0 or 1 token for this platform

        # Keep the most recent, delete the rest
        most_recent = tokens.first
        old_tokens = tokens[1..]

        puts "\nUser #{user.id} (#{user.email_address}):"
        puts "  Platform: #{platform}"
        puts "  Total tokens: #{tokens.count}"
        puts "  Keeping: #{most_recent.token[0..20]}... (last used: #{most_recent.last_used_at})"

        old_tokens.each do |token|
          puts "  Deleting: #{token.token[0..20]}... (last used: #{token.last_used_at || 'never'})"
          token.destroy
          deleted_count += 1
        end

        user_count += 1
      end
    end

    puts "\n" + "=" * 80
    puts "Cleanup complete!"
    puts "Users affected: #{user_count}"
    puts "Old tokens deleted: #{deleted_count}"
    puts "=" * 80
  end

  desc 'Show device token statistics'
  task stats: :environment do
    puts "Device Token Statistics"
    puts "=" * 80

    total_tokens = DeviceToken.count
    total_users = DeviceToken.distinct.count(:user_id)
    active_tokens = DeviceToken.active.count

    puts "Total device tokens: #{total_tokens}"
    puts "Total users with tokens: #{total_users}"
    puts "Active tokens (used in last 30 days): #{active_tokens}"
    puts "Inactive tokens: #{total_tokens - active_tokens}"
    puts

    # Platform breakdown
    puts "Tokens by platform:"
    DeviceToken.group(:platform).count.each do |platform, count|
      puts "  #{platform}: #{count}"
    end
    puts

    # Users with multiple tokens for same platform
    puts "Users with duplicate tokens (same platform):"
    duplicates = 0
    %w[ios android].each do |platform|
      DeviceToken.where(platform: platform)
        .group(:user_id)
        .having('COUNT(*) > 1')
        .count.each do |user_id, count|
        user = User.find(user_id)
        puts "  User #{user_id} (#{user.email_address}): #{count} #{platform} tokens"
        duplicates += count - 1 # Count extras only
      end
    end
    puts "Total duplicate tokens: #{duplicates}"
    puts "=" * 80
  end
end
