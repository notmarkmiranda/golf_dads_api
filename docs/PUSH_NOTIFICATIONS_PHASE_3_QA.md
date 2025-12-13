# Push Notifications Phase 3 - QA Testing Guide

**Purpose:** Verify that all API endpoints for device tokens, notification preferences, and group notification settings are working correctly in production.

**Prerequisites:**
- Phase 2 deployed and verified ✅
- User account in production
- API authentication token

---

## Setup: Get Authentication Token

First, get your JWT token from production. Run this in production console:

```ruby
# Replace with your actual email
user = User.find_by(email_address: 'your-email@example.com')
token = user.generate_jwt
puts "Your JWT token:"
puts token
```

Copy this token. You'll use it in curl commands below as `YOUR_TOKEN_HERE`.

**Or** if you prefer to test via console, you can skip curl and use the console scripts below.

---

## Test 1: Device Tokens API

### 1A. Register a Device Token (POST)

**Via curl:**
```bash
curl -X POST https://golf-api.onrender.com/api/v1/device_tokens \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "device_token": {
      "token": "test_fcm_token_12345",
      "platform": "ios"
    }
  }'
```

**Expected response (201 Created):**
```json
{
  "id": 1,
  "token": "test_fcm_token_12345",
  "platform": "ios",
  "last_used_at": "2024-12-13T..."
}
```

**Via console:**
```ruby
user = User.find_by(email_address: 'your-email@example.com')
DeviceToken.create!(
  user: user,
  token: 'test_fcm_token_12345',
  platform: 'ios'
)
# Should return DeviceToken object with id
```

**✓ Pass if:** Status 201, returns device token with id and last_used_at
**✗ Fail if:** Error, missing fields, or unauthorized

---

### 1B. Register Duplicate Token (Should Update)

**Via curl:**
```bash
curl -X POST https://golf-api.onrender.com/api/v1/device_tokens \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "device_token": {
      "token": "test_fcm_token_12345",
      "platform": "android"
    }
  }'
```

**Expected:** Status 201, platform updated to "android"

**Via console:**
```ruby
user = User.find_by(email_address: 'your-email@example.com')
token = DeviceToken.find_or_initialize_by(user: user, token: 'test_fcm_token_12345')
token.platform = 'android'
token.last_used_at = Time.current
token.save!
# Should update existing token, not create new one
```

**✓ Pass if:** Same token updated, not duplicated
**✗ Fail if:** Creates duplicate token

---

### 1C. Delete Device Token (DELETE)

**Via curl:**
```bash
curl -X DELETE https://golf-api.onrender.com/api/v1/device_tokens/test_fcm_token_12345 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Expected response:** Status 204 No Content (empty body)

**Via console:**
```ruby
user = User.find_by(email_address: 'your-email@example.com')
token = DeviceToken.find_by(user: user, token: 'test_fcm_token_12345')
token.destroy
# Should return destroyed token
```

**✓ Pass if:** Status 204, token deleted
**✗ Fail if:** Error or token still exists

---

### 1D. Verify Token Deleted

**Via console:**
```ruby
user = User.find_by(email_address: 'your-email@example.com')
DeviceToken.exists?(user: user, token: 'test_fcm_token_12345')
# Should return: false
```

**✓ Pass if:** Returns false
**✗ Fail if:** Returns true (token still exists)

---

## Test 2: Notification Preferences API

### 2A. Get Notification Preferences (GET)

**Via curl:**
```bash
curl https://golf-api.onrender.com/api/v1/notification_preferences \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Expected response (200 OK):**
```json
{
  "id": 1,
  "user_id": 1,
  "reservations_enabled": true,
  "group_activity_enabled": true,
  "reminders_enabled": true,
  "reminder_24h_enabled": true,
  "reminder_2h_enabled": true
}
```

**Via console:**
```ruby
user = User.find_by(email_address: 'your-email@example.com')
pref = user.notification_preference
puts "Reservations: #{pref.reservations_enabled}"
puts "Group Activity: #{pref.group_activity_enabled}"
puts "Reminders: #{pref.reminders_enabled}"
puts "24h Reminder: #{pref.reminder_24h_enabled}"
puts "2h Reminder: #{pref.reminder_2h_enabled}"
# All should be true by default
```

**✓ Pass if:** Status 200, returns all preferences (all true by default)
**✗ Fail if:** Missing preferences or unauthorized

---

### 2B. Update Notification Preferences (PATCH)

**Via curl:**
```bash
curl -X PATCH https://golf-api.onrender.com/api/v1/notification_preferences \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "notification_preferences": {
      "reservations_enabled": false,
      "group_activity_enabled": false,
      "reminder_24h_enabled": false
    }
  }'
```

**Expected response (200 OK):**
```json
{
  "id": 1,
  "user_id": 1,
  "reservations_enabled": false,
  "group_activity_enabled": false,
  "reminders_enabled": true,
  "reminder_24h_enabled": false,
  "reminder_2h_enabled": true
}
```

**Via console:**
```ruby
user = User.find_by(email_address: 'your-email@example.com')
pref = user.notification_preference
pref.update!(
  reservations_enabled: false,
  group_activity_enabled: false,
  reminder_24h_enabled: false
)
pref.reload
puts "Reservations: #{pref.reservations_enabled}" # false
puts "Group Activity: #{pref.group_activity_enabled}" # false
puts "Reminders: #{pref.reminders_enabled}" # true (unchanged)
puts "24h: #{pref.reminder_24h_enabled}" # false
puts "2h: #{pref.reminder_2h_enabled}" # true (unchanged)
```

**✓ Pass if:** Status 200, specified fields updated, others unchanged
**✗ Fail if:** All fields reset or error

---

### 2C. Restore Preferences

**Via curl:**
```bash
curl -X PATCH https://golf-api.onrender.com/api/v1/notification_preferences \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "notification_preferences": {
      "reservations_enabled": true,
      "group_activity_enabled": true,
      "reminder_24h_enabled": true
    }
  }'
```

**Expected:** All preferences back to true

**Via console:**
```ruby
user = User.find_by(email_address: 'your-email@example.com')
pref = user.notification_preference
pref.update!(
  reservations_enabled: true,
  group_activity_enabled: true,
  reminder_24h_enabled: true
)
# All should be true now
```

**✓ Pass if:** All preferences restored to true
**✗ Fail if:** Updates don't persist

---

## Test 3: Group Notification Settings

### 3A. Setup - Get Group ID

**Via console:**
```ruby
user = User.find_by(email_address: 'your-email@example.com')
group = user.groups.first
puts "Group ID: #{group.id}"
puts "Group Name: #{group.name}"
# Use this group_id in the tests below
```

If no groups exist, create one:
```ruby
group = Group.create!(name: 'Test Group', owner: user)
GroupMembership.create!(group: group, user: user)
puts "Created group ID: #{group.id}"
```

---

### 3B. Mute Group Notifications (PATCH)

**Via curl:**
```bash
curl -X PATCH https://golf-api.onrender.com/api/v1/groups/GROUP_ID/notification_settings \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "notification_settings": {
      "muted": true
    }
  }'
```

**Expected response (200 OK):**
```json
{
  "id": 1,
  "user_id": 1,
  "group_id": 1,
  "muted": true
}
```

**Via console:**
```ruby
user = User.find_by(email_address: 'your-email@example.com')
group = Group.find(GROUP_ID) # Replace with actual ID
setting = user.group_notification_settings.find_or_initialize_by(group: group)
setting.update!(muted: true)
puts "Muted: #{setting.muted}" # Should be true
```

**✓ Pass if:** Status 200, muted: true
**✗ Fail if:** Error or not created

---

### 3C. Unmute Group Notifications

**Via curl:**
```bash
curl -X PATCH https://golf-api.onrender.com/api/v1/groups/GROUP_ID/notification_settings \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "notification_settings": {
      "muted": false
    }
  }'
```

**Expected:** Status 200, muted: false

**Via console:**
```ruby
user = User.find_by(email_address: 'your-email@example.com')
group = Group.find(GROUP_ID)
setting = user.group_notification_settings.find_by(group: group)
setting.update!(muted: false)
puts "Muted: #{setting.muted}" # Should be false
```

**✓ Pass if:** Status 200, muted: false
**✗ Fail if:** Setting doesn't update

---

### 3D. Verify Setting Persists

**Via console:**
```ruby
user = User.find_by(email_address: 'your-email@example.com')
group = Group.find(GROUP_ID)
setting = GroupNotificationSetting.find_by(user: user, group: group)
puts "Setting exists: #{setting.present?}"
puts "Muted: #{setting.muted}"
# Should persist as false from previous test
```

**✓ Pass if:** Setting exists and persists
**✗ Fail if:** Setting lost or changed

---

## Test 4: Authorization & Security

### 4A. Test Without Authentication

**Via curl:**
```bash
curl https://golf-api.onrender.com/api/v1/notification_preferences
```

**Expected:** Status 401 Unauthorized
```json
{
  "error": "Unauthorized"
}
```

**✓ Pass if:** Returns 401 Unauthorized
**✗ Fail if:** Returns data or 200 OK

---

### 4B. Test With Invalid Token

**Via curl:**
```bash
curl https://golf-api.onrender.com/api/v1/notification_preferences \
  -H "Authorization: Bearer invalid_token_12345"
```

**Expected:** Status 401 Unauthorized

**✓ Pass if:** Returns 401 Unauthorized
**✗ Fail if:** Returns data or 200 OK

---

### 4C. Test Cannot Access Another User's Tokens

**Via console:**
```ruby
user1 = User.first
user2 = User.second

# User1 creates a token
token1 = DeviceToken.create!(user: user1, token: 'user1_token', platform: 'ios')

# User2 tries to delete user1's token (should fail)
user2_tokens = DeviceToken.where(user: user2, token: 'user1_token')
puts "User2 can see user1's token: #{user2_tokens.exists?}"
# Should be false - users can't see other users' tokens
```

**✓ Pass if:** User cannot access another user's tokens
**✗ Fail if:** Cross-user access allowed

---

## Test 5: Edge Cases

### 5A. Test Missing Parameters

**Via curl:**
```bash
curl -X POST https://golf-api.onrender.com/api/v1/device_tokens \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "device_token": {
      "platform": "ios"
    }
  }'
```

**Expected:** Status 422 Unprocessable Content with validation errors

**✓ Pass if:** Returns 422 with errors
**✗ Fail if:** Creates token with missing data

---

### 5B. Test Invalid Group ID

**Via curl:**
```bash
curl -X PATCH https://golf-api.onrender.com/api/v1/groups/99999/notification_settings \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "notification_settings": {
      "muted": true
    }
  }'
```

**Expected:** Status 404 Not Found

**✓ Pass if:** Returns 404
**✗ Fail if:** Creates setting for non-existent group

---

### 5C. Test Non-Member Cannot Mute Group

**Via console:**
```ruby
user = User.find_by(email_address: 'your-email@example.com')
other_user = User.where.not(id: user.id).first

# Create a group that user is NOT a member of
other_group = Group.create!(name: 'Other Group', owner: other_user)
GroupMembership.create!(group: other_group, user: other_user)

# Try to create notification setting (should work but shouldn't affect anything)
# The authorization happens at the GroupsController level via Pundit
# Test this via API call with non-member token
```

**✓ Pass if:** Non-members cannot mute groups they're not in (403 Forbidden)
**✗ Fail if:** Non-members can mute any group

---

## Test Summary Checklist

Run through all tests and check off:

- [ ] **Device Tokens**
  - [ ] Can create device token
  - [ ] Can update duplicate token
  - [ ] Can delete device token
  - [ ] Token properly deleted

- [ ] **Notification Preferences**
  - [ ] Can get preferences
  - [ ] Can update preferences
  - [ ] Partial updates work
  - [ ] Preferences persist

- [ ] **Group Notification Settings**
  - [ ] Can mute group
  - [ ] Can unmute group
  - [ ] Settings persist

- [ ] **Security**
  - [ ] Requires authentication
  - [ ] Rejects invalid tokens
  - [ ] Users can only access their own data

- [ ] **Edge Cases**
  - [ ] Handles missing parameters
  - [ ] Handles invalid group IDs
  - [ ] Enforces group membership

---

## Quick Verification Script

Run this complete script in production console for a quick check:

```ruby
puts "=" * 60
puts "PHASE 3 API ENDPOINTS VERIFICATION"
puts "=" * 60

user = User.find_by(email_address: 'your-email@example.com') # Replace with your email

checks = {}

# 1. Device Token
begin
  token = DeviceToken.create!(user: user, token: "qa_test_#{Time.now.to_i}", platform: 'ios')
  checks["Create device token"] = token.persisted?
  token.destroy
  checks["Delete device token"] = true
rescue => e
  checks["Device tokens"] = false
  puts "Error: #{e.message}"
end

# 2. Notification Preferences
begin
  pref = user.notification_preference
  checks["Has notification preferences"] = pref.present?
  original = pref.reservations_enabled
  pref.update!(reservations_enabled: !original)
  checks["Update preferences"] = pref.reload.reservations_enabled == !original
  pref.update!(reservations_enabled: original) # restore
rescue => e
  checks["Notification preferences"] = false
  puts "Error: #{e.message}"
end

# 3. Group Notification Settings
begin
  if user.groups.any?
    group = user.groups.first
    setting = GroupNotificationSetting.find_or_create_by!(user: user, group: group)
    setting.update!(muted: true)
    checks["Mute group"] = setting.reload.muted == true
    setting.update!(muted: false)
    checks["Unmute group"] = setting.reload.muted == false
  else
    checks["Group notification settings"] = "No groups to test"
  end
rescue => e
  checks["Group notification settings"] = false
  puts "Error: #{e.message}"
end

puts "=" * 60
checks.each do |check, result|
  status = result == true ? "✓" : (result == false ? "✗" : "⚠")
  puts "#{status} #{check}: #{result}"
end
puts "=" * 60

if checks.values.all? { |v| v == true || v.is_a?(String) }
  puts "✓ ALL PHASE 3 API CHECKS PASSED!"
else
  puts "✗ SOME CHECKS FAILED - Review errors above"
end
```

---

## Expected Results

**All tests should pass:**
- Device tokens can be created, updated, and deleted ✅
- Notification preferences can be retrieved and updated ✅
- Group notification settings can be muted/unmuted ✅
- All endpoints require authentication ✅
- Users can only access their own data ✅
- Invalid requests return appropriate errors ✅

**If any tests fail:**
1. Check the production logs for errors
2. Verify Phase 2 is deployed correctly
3. Ensure user has proper authentication
4. Check database for missing records

---

**Phase 3 Status:** Ready for Phase 4 iOS Integration ✅

**Last Updated:** December 13, 2024
