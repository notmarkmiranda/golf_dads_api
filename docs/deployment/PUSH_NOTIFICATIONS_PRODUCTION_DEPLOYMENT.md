# Push Notifications - Production Deployment Guide

**Status:** ✅ DEPLOYED
**Date:** December 13, 2024

---

## Deployment Complete

Phase 1 & 2 push notifications are now fully deployed to production:
1. ✅ FCM credentials file configured
2. ✅ Solid Queue tables created
3. ✅ All migrations applied

---

## Step 1: Add FCM Credentials to Render

### A. Get the Firebase Service Account JSON

You should already have this file locally at:
```
/Users/weatherby/Development/golf_dads/golf_api/config/firebase-service-account.json
```

If not, download it from Firebase Console:
1. Go to https://console.firebase.google.com
2. Select project: **three-putt**
3. Click gear icon → Project settings
4. Go to "Service accounts" tab
5. Click "Generate new private key"
6. Save as `firebase-service-account.json`

### B. Add to Render as Secret File

1. Go to Render Dashboard: https://dashboard.render.com
2. Select your service: **golf-api** (or whatever it's named)
3. Go to "Environment" tab
4. Scroll down to "Secret Files" section
5. Click "Add Secret File"
6. Configure:
   - **Filename:** `firebaseserviceaccount.json` (no path separator - Render doesn't allow `/`)
   - **Contents:** Paste the entire JSON file contents
7. Click "Save Changes"
8. Update Environment Variable:
   - Set `FCM_CREDENTIALS_PATH=/etc/secrets/firebaseserviceaccount.json`
   - Render places Secret Files at `/etc/secrets/`

This will make the file available at `/etc/secrets/firebaseserviceaccount.json` in production.

---

## Step 2: Deploy and Run Migrations

### Check Your Render Build Command

1. Go to Render Dashboard → Your service → Settings
2. Check "Build Command" - Should include:
   ```bash
   bundle install; rails db:migrate
   ```
3. If it doesn't have `rails db:migrate`, update it to:
   ```bash
   bundle install; rails db:migrate; rails db:schema:load:queue
   ```

### Trigger Deployment

**The Phase 1 migrations should run automatically** when you deploy.

1. Go to Render Dashboard
2. Click "Manual Deploy" → "Deploy latest commit"
3. Watch the build logs - you should see migrations running

**Expected in deploy logs:**
```
Running: rails db:migrate
== 20251213042900 CreateDeviceTokens: migrating ==============================
-- create_table(:device_tokens)
   -> 0.0123s
...
== 20251213043331 AddNotificationPreferencesToExistingUsers: migrated ========
```

### Solid Queue Tables (Separate Step Required)

**Important:** Solid Queue tables need to be created manually:

After deployment completes, run in Render Shell:
```bash
rails solid_queue:setup_tables
```

This creates all the `solid_queue_*` tables.

**Why?** Solid Queue uses a separate schema file (`db/queue_schema.rb`) that can't be loaded in production due to environment protection. The `solid_queue:setup_tables` rake task manually creates all required tables.

---

## Step 3: Verify Solid Queue Worker is Running

### Check Worker Process

In Render Dashboard:
1. Go to your service
2. Check if you have a **Background Worker** running
3. If not, you need to add one

### Option 1: Add Background Worker (Recommended)

1. In Render Dashboard, click "New +"
2. Select "Background Worker"
3. Configure:
   - **Name:** `golf-api-worker`
   - **Environment:** Same as web service
   - **Build Command:** `bundle install`
   - **Start Command:** `bundle exec rake solid_queue:start`
   - **Instance Type:** Same as web service (or smaller)
4. Click "Create Background Worker"

### Option 2: Use Procfile (Alternative)

If you want both web and worker in one process:

1. Go to service settings
2. Change "Start Command" to: `foreman start -f Procfile`
3. This will start both web and worker from the Procfile we created

**Note:** Render's free tier supports 1 web + 1 worker.

---

## Step 4: Verify Production Setup

Run these commands in production console:

```ruby
# 1. Check FCM file exists
File.exist?(Rails.root.join('config/firebase-service-account.json'))
# Should return: true

# 2. Check FCM config
FCM_CONFIG
# Should show: { project_id: "three-putt", credentials_path: "config/firebase-service-account.json" }

# 3. Check Solid Queue tables
ActiveRecord::Base.connection.table_exists?('solid_queue_jobs')
# Should return: true

# 4. Check notification tables
tables = %w[device_tokens notification_preferences group_notification_settings notification_logs]
tables.all? { |t| ActiveRecord::Base.connection.table_exists?(t) }
# Should return: true

# 5. Check all users have preferences
User.count == NotificationPreference.count
# Should return: true

# 6. Check Solid Queue adapter
ActiveJob::Base.queue_adapter.class
# Should return: ActiveJob::QueueAdapters::SolidQueueAdapter

# 7. Test creating a notification preference
user = User.first
user.notification_preference
# Should return: NotificationPreference object (not nil)
```

---

## Step 5: Run QA Script

Once the above steps are complete, run the full QA script from:
`docs/PUSH_NOTIFICATIONS_PHASE_2_QA.md`

All tests should pass except:
- FCM API calls will fail (expected - no valid APNs key yet)
- Actual notifications won't send (expected - no iOS devices registered)

---

## Troubleshooting

### Issue: FCM file still not found after adding Secret File

**Solution:**
1. Check the filename exactly matches: `config/firebase-service-account.json`
2. Redeploy the service after adding Secret File
3. Verify in console:
   ```ruby
   Dir.glob(Rails.root.join('config', '*.json'))
   ```

### Issue: Migrations fail with "already exists"

**Solution:**
```bash
# Check migration status
rails db:migrate:status

# If migrations already ran, you're good
# If some are down, run specific migration:
rails db:migrate:up VERSION=20251213042900
```

### Issue: Solid Queue tables still don't exist

**Solution:**
```bash
# Force load the queue schema
rails db:schema:load:queue RAILS_ENV=production

# Or run the Solid Queue install command
rails solid_queue:install
rails db:migrate
```

### Issue: Worker process not starting

**Check logs:**
1. Go to Render Dashboard
2. Select your worker service
3. Check "Logs" tab
4. Look for errors

**Common issues:**
- Missing environment variables (copy from web service)
- Database connection issues (check DATABASE_URL)
- Gem installation failed (check build logs)

### Issue: Jobs enqueued but not processing

**Check:**
```ruby
# In production console
SolidQueue::Job.pending.count
# If > 0, jobs are enqueued but not processing

# Check if worker is running
SolidQueue::Process.all
# Should return worker processes

# Manually dispatch a job (testing only)
job = SolidQueue::Job.pending.first
job.dispatch if job
```

---

## Environment Variables Checklist

Make sure these are set in Render:

**Required:**
- ✅ `DATABASE_URL` - PostgreSQL connection string
- ✅ `FCM_PROJECT_ID` - Set to: `three-putt`
- ✅ `FCM_CREDENTIALS_PATH` - Set to: `config/firebase-service-account.json`
- ✅ `RAILS_ENV` - Set to: `production`
- ✅ `RAILS_MASTER_KEY` - Your master key

**Optional but recommended:**
- `RAILS_LOG_LEVEL` - Set to: `info`
- `RAILS_MAX_THREADS` - Set to: `5`

---

## Deployment Checklist

- [ ] FCM credentials file added to Render Secret Files
- [ ] Phase 1 migrations run (`rails db:migrate`)
- [ ] Solid Queue schema loaded (`rails db:schema:load:queue`)
- [ ] All users have notification preferences created
- [ ] Solid Queue worker process configured and running
- [ ] Environment variables verified
- [ ] Production QA tests pass
- [ ] Test job can be enqueued
- [ ] Worker processes jobs (check logs)

---

## Post-Deployment Verification

```ruby
# Run this complete check in production console:

puts "=" * 60
puts "PRODUCTION DEPLOYMENT VERIFICATION"
puts "=" * 60

checks = {
  "FCM file exists" => File.exist?('/etc/secrets/firebaseserviceaccount.json'),
  "FCM project ID set" => FCM_CONFIG[:project_id].present?,
  "Solid Queue tables exist" => ActiveRecord::Base.connection.table_exists?('solid_queue_jobs'),
  "Device tokens table" => ActiveRecord::Base.connection.table_exists?('device_tokens'),
  "Notification preferences table" => ActiveRecord::Base.connection.table_exists?('notification_preferences'),
  "All users have preferences" => User.count == NotificationPreference.count,
  "Solid Queue adapter active" => ActiveJob::Base.queue_adapter.is_a?(ActiveJob::QueueAdapters::SolidQueueAdapter),
  "Can create notification log" => NotificationLog.new(user: User.first, notification_type: 'reminder_24h', status: 'pending', title: 'test', body: 'test').valid?
}

checks.each do |check, result|
  status = result ? "✓" : "✗"
  puts "#{status} #{check}"
end

puts "=" * 60

if checks.values.all?
  puts "✓ ALL CHECKS PASSED - Ready for Phase 3!"
else
  puts "✗ Some checks failed - see troubleshooting guide"
end
```

---

## Next Steps After Deployment

Once all checks pass:
1. ✅ Phase 1 & 2 are fully deployed
2. ➡️ Proceed to Phase 3: API Endpoints
3. ➡️ Then Phase 4-5: iOS Integration

---

**Last Updated:** December 13, 2024
