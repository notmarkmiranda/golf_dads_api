# Production Setup - Quick Guide

**Phase 1 & 2 are already deployed!** Migrations ran automatically when you pushed.

You just need **2 quick steps** to complete setup:

---

## Step 1: Add FCM Credentials (2 minutes)

1. Open your local file:
   ```
   /Users/weatherby/Development/golf_dads/golf_api/config/firebase-service-account.json
   ```

2. Go to Render Dashboard → Your service → Environment tab

3. Scroll to "Secret Files" section → Click "Add Secret File"

4. Set:
   - **Filename:** `config/firebase-service-account.json`
   - **Contents:** (paste the entire JSON file)

5. Click "Save Changes"

6. Service will redeploy automatically

---

## Step 2: Load Solid Queue Schema (30 seconds)

1. Go to Render Dashboard → Your service → Shell tab

2. Run:
   ```bash
   rails db:schema:load:queue
   ```

3. You should see:
   ```
   Created database 'solid_queue'
   ```

**Done!** This creates the Solid Queue tables.

---

## Step 3: Add Worker Process (Optional - 2 minutes)

For background jobs to actually process, you need a worker:

1. Render Dashboard → Click "New +"
2. Select "Background Worker"
3. Configure:
   - **Name:** `golf-api-worker`
   - **Start Command:** `bundle exec rake solid_queue:start`
   - Link to same database/environment as web service
4. Click "Create"

**OR** skip this and jobs will queue but not process until you add worker later.

---

## Verification (30 seconds)

Run in production console:

```ruby
# Quick check
puts "FCM: #{File.exist?(Rails.root.join('config/firebase-service-account.json'))}"
puts "Tables: #{ActiveRecord::Base.connection.table_exists?('solid_queue_jobs')}"
puts "Prefs: #{User.count == NotificationPreference.count}"

# Should all be true
```

**If all true → Phase 2 is live! ✅**

---

## What's Working Now

- ✅ All Phase 1 database tables created
- ✅ All users have notification preferences
- ✅ Models with callbacks ready
- ✅ Background jobs can be enqueued
- ✅ FCM configuration present (after Step 1)
- ✅ Solid Queue tables present (after Step 2)

## What's NOT Working Yet

- ❌ Actual push notifications (need iOS app - Phase 4-5)
- ❌ Background jobs won't process (need worker - Step 3)
- ❌ FCM API calls fail (need APNs key upload)

This is **expected and correct** for Phase 2!

---

**Next:** After these 2 steps, run the full QA script from `PUSH_NOTIFICATIONS_PHASE_2_QA.md`
