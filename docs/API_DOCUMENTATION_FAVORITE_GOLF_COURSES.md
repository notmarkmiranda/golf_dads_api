# Favorite Golf Courses API Documentation

## Overview

The Favorite Golf Courses API allows users to bookmark golf courses for quick access when creating tee times. Users can add courses to their favorites, view their favorite courses, and remove courses from their favorites.

**Status:** ✅ Complete (December 2024)

---

## Endpoints

### 1. List Favorite Courses

Get all golf courses that the current user has favorited.

```bash
GET /api/v1/favorite_golf_courses
```

**Headers:**
- `Authorization: Bearer <token>` (required)

**Response (200 OK):**
```json
{
  "golf_courses": [
    {
      "id": 1,
      "external_id": 18300,
      "name": "Pebble Beach Golf Links",
      "club_name": "Pebble Beach Company",
      "address": "1700 17 Mile Dr",
      "city": "Pebble Beach",
      "state": "CA",
      "zip_code": "93953",
      "country": "USA",
      "latitude": 36.5674,
      "longitude": -121.95,
      "phone": "+1-800-654-9300",
      "website": "https://www.pebblebeach.com",
      "is_favorite": true
    }
  ]
}
```

**Features:**
- Returns courses in reverse chronological order (most recently favorited first)
- Always includes `is_favorite: true` for all returned courses
- Returns empty array if user has no favorites

**Error Responses:**

- `401 Unauthorized` - Not authenticated
```json
{
  "error": "Unauthorized"
}
```

---

### 2. Add Course to Favorites

Add a golf course to the current user's favorites list.

```bash
POST /api/v1/favorite_golf_courses
```

**Headers:**
- `Authorization: Bearer <token>` (required)
- `Content-Type: application/json`

**Request Body:**
```json
{
  "golf_course_id": 123
}
```

**Response (201 Created):**
```json
{
  "golf_course": {
    "id": 123,
    "external_id": 18300,
    "name": "Pebble Beach Golf Links",
    "club_name": "Pebble Beach Company",
    "address": "1700 17 Mile Dr",
    "city": "Pebble Beach",
    "state": "CA",
    "zip_code": "93953",
    "country": "USA",
    "latitude": 36.5674,
    "longitude": -121.9500,
    "phone": "+1-800-654-9300",
    "website": "https://www.pebblebeach.com",
    "is_favorite": true
  },
  "message": "Course added to favorites"
}
```

**Error Responses:**

- `401 Unauthorized` - Not authenticated
```json
{
  "error": "Unauthorized"
}
```

- `404 Not Found` - Golf course doesn't exist
```json
{
  "error": "Golf course not found"
}
```

- `422 Unprocessable Entity` - Course already favorited
```json
{
  "error": "User has already favorited this course"
}
```

---

### 3. Remove Course from Favorites

Remove a golf course from the current user's favorites list.

```bash
DELETE /api/v1/favorite_golf_courses/:golf_course_id
```

**Headers:**
- `Authorization: Bearer <token>` (required)

**URL Parameters:**
- `golf_course_id` - The ID of the golf course to remove

**Response (200 OK):**
```json
{
  "golf_course": {
    "id": 123,
    "external_id": 18300,
    "name": "Pebble Beach Golf Links",
    "club_name": "Pebble Beach Company",
    "address": "1700 17 Mile Dr",
    "city": "Pebble Beach",
    "state": "CA",
    "zip_code": "93953",
    "country": "USA",
    "latitude": 36.5674,
    "longitude": -121.9500,
    "phone": "+1-800-654-9300",
    "website": "https://www.pebblebeach.com",
    "is_favorite": false
  },
  "message": "Course removed from favorites"
}
```

**Error Responses:**

- `401 Unauthorized` - Not authenticated
```json
{
  "error": "Unauthorized"
}
```

- `404 Not Found` - Golf course doesn't exist
```json
{
  "error": "Golf course not found"
}
```

- `404 Not Found` - Course is not in user's favorites
```json
{
  "error": "Course is not in favorites"
}
```

---

## Integration with Golf Courses API

### is_favorite Flag

All golf course endpoints now include an `is_favorite` boolean field that indicates whether the current authenticated user has favorited that course.

**Affected Endpoints:**
- `GET /api/v1/golf_courses/search` - Search results include favorite status
- `GET /api/v1/golf_courses/nearby` - Nearby courses include favorite status
- `POST /api/v1/golf_courses/cache` - Cached course response includes favorite status

**Example:**
```bash
GET /api/v1/golf_courses/search?query=pebble
Authorization: Bearer <token>
```

**Response:**
```json
{
  "golf_courses": [
    {
      "id": 1,
      "name": "Pebble Beach Golf Links",
      "city": "Pebble Beach",
      "state": "CA",
      "is_favorite": true
    },
    {
      "id": 2,
      "name": "Pebble Creek Golf Club",
      "city": "Salt Lake City",
      "state": "UT",
      "is_favorite": false
    }
  ]
}
```

**Behavior:**
- Returns `true` if the authenticated user has favorited the course
- Returns `false` if the user hasn't favorited the course
- Always returns `false` for unauthenticated requests

---

## Authorization

All favorite golf courses endpoints require authentication. Only authenticated users can:
- View their own favorites
- Add courses to their favorites
- Remove courses from their favorites

**Authorization Rules:**
- Users can only view and manage their own favorites
- Users cannot see other users' favorites
- Users cannot modify other users' favorites

---

## Database Schema

### favorite_golf_courses Table

| Column | Type | Description |
|--------|------|-------------|
| id | integer | Primary key |
| user_id | integer | Foreign key to users table (NOT NULL) |
| golf_course_id | integer | Foreign key to golf_courses table (NOT NULL) |
| created_at | timestamp | When the favorite was created |
| updated_at | timestamp | When the favorite was last updated |

**Indexes:**
- `index_favorite_courses_on_user_and_course` - Unique composite index on (user_id, golf_course_id)
- Prevents duplicate favorites

**Associations:**
- `belongs_to :user`
- `belongs_to :golf_course`

---

## Example cURL Commands

### List favorites
```bash
curl -X GET http://localhost:3000/api/v1/favorite_golf_courses \
  -H "Authorization: Bearer $TOKEN"
```

### Add favorite
```bash
curl -X POST http://localhost:3000/api/v1/favorite_golf_courses \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "golf_course_id": 123
  }'
```

### Remove favorite
```bash
curl -X DELETE http://localhost:3000/api/v1/favorite_golf_courses/123 \
  -H "Authorization: Bearer $TOKEN"
```

### Search courses (with is_favorite flag)
```bash
curl -X GET "http://localhost:3000/api/v1/golf_courses/search?query=pebble" \
  -H "Authorization: Bearer $TOKEN"
```

---

## User Model Integration

### New Associations

```ruby
class User < ApplicationRecord
  has_many :favorite_golf_courses, dependent: :destroy
  has_many :favorites, through: :favorite_golf_courses, source: :golf_course
end
```

### Helper Methods

```ruby
# Check if user has favorited a course
user.favorited?(golf_course)  # => true/false

# Get all favorite courses
user.favorites  # => [GolfCourse, GolfCourse, ...]

# Add a favorite
user.favorites << golf_course

# Remove a favorite
user.favorites.destroy(golf_course)
```

---

## GolfCourse Model Integration

### New Associations

```ruby
class GolfCourse < ApplicationRecord
  has_many :favorite_golf_courses, dependent: :destroy
  has_many :favorited_by_users, through: :favorite_golf_courses, source: :user
end
```

### Usage

```ruby
# Get all users who favorited this course
golf_course.favorited_by_users  # => [User, User, ...]

# Count favorites
golf_course.favorited_by_users.count
```

---

## Testing

### RSpec Tests

Comprehensive test coverage includes:
- ✅ Listing favorites (empty and populated)
- ✅ Adding courses to favorites
- ✅ Preventing duplicate favorites
- ✅ Removing courses from favorites
- ✅ 404 handling for invalid course IDs
- ✅ Authentication requirements
- ✅ Reverse chronological ordering
- ✅ User isolation (can't modify other users' favorites)

Run tests:
```bash
rspec spec/requests/api/v1/favorite_golf_courses_spec.rb
```

### Manual Testing Checklist

- [ ] List favorites when empty
- [ ] Add a course to favorites
- [ ] List favorites shows the added course
- [ ] Try to add the same course again (should fail)
- [ ] Remove course from favorites
- [ ] List favorites is empty again
- [ ] Search for courses shows correct is_favorite flags
- [ ] Try to access endpoints without authentication (should fail)
- [ ] Try to delete a course that isn't favorited (should fail)

---

## Performance Considerations

### Database Queries

**Optimized Queries:**
- `GET /api/v1/favorite_golf_courses` - Single query with join
- `user.favorited?(course)` - Uses `exists?` query (fast)
- Unique index prevents duplicate favorites at database level

**N+1 Query Prevention:**
- The `is_favorite` flag in course responses uses a single `exists?` query per course
- For bulk operations, consider adding eager loading if performance issues arise

### Caching Opportunities (Future)

If favorite checks become a bottleneck:
1. Add counter cache: `favorites_count` on golf_courses table
2. Cache favorite IDs in Redis per user session
3. Use `user.favorites.pluck(:id)` and check with `include?` for bulk operations

---

## Future Enhancements

### Potential Features

1. **Reordering Favorites**
   - Add `position` column to `favorite_golf_courses`
   - Allow users to drag-and-drop reorder

2. **Favorite Notes**
   - Add `notes` text column to `favorite_golf_courses`
   - Let users add personal notes about each favorite course

3. **Favorite Collections**
   - Allow users to organize favorites into groups
   - "Vacation Courses", "Local Favorites", etc.

4. **Social Features**
   - See which courses friends have favorited
   - "Most favorited by your groups" recommendations

5. **Analytics**
   - Track most favorited courses globally
   - Show "Popular in your area" based on favorites

6. **Notifications**
   - Notify when new tee times are posted at favorite courses
   - Email digest of activity at favorite courses

---

## Troubleshooting

### "Course is not in favorites" Error

**Cause:** Trying to remove a course that isn't actually favorited by the user

**Solutions:**
1. Check if course is in user's favorites first
2. Verify correct course ID is being used
3. Ensure user is authenticated

### "User has already favorited this course" Error

**Cause:** Trying to add a course that's already in favorites

**Solutions:**
1. Check `is_favorite` flag before attempting to add
2. Use toggle logic in frontend: if favorited, remove; else add
3. Unique database constraint prevents duplicates

### Slow Performance

**Cause:** N+1 queries when checking `is_favorite` for many courses

**Solutions:**
1. For bulk operations, fetch all favorite IDs first: `user.favorites.pluck(:id)`
2. Use `Array#include?` for membership checks
3. Consider adding Redis caching for active users

---

## Security Considerations

### Authorization

- ✅ Users can only manage their own favorites
- ✅ Pundit policy enforces user ownership
- ✅ No way to view or modify other users' favorites
- ✅ All endpoints require authentication

### Data Privacy

- User favorites are private by default
- No public endpoint to view user favorites
- No leakage of favorite data through other APIs

### Rate Limiting (Future)

Consider adding rate limits:
- Max 100 favorites per user
- Max 10 favorite additions per minute
- Prevents abuse and spam

---

## Migration Notes

### Adding to Existing Database

The migration is backward compatible:
- No changes to existing tables
- New join table with proper indexes
- Foreign keys ensure referential integrity
- Can roll back without data loss

### Rolling Back

```bash
rails db:rollback
```

This will:
- Drop the `favorite_golf_courses` table
- Remove all favorite data
- Restore database to previous state

---

## Version History

- **v1.0** (December 2024) - Initial release
  - List, add, and remove favorites
  - `is_favorite` flag in all course responses
  - Comprehensive test coverage
  - Full API documentation

---

## Support

For issues or questions:
- Check Rails logs: `tail -f log/development.log`
- Review RSpec tests for expected behavior
- Verify authentication token is valid
- Ensure database migrations are up to date: `rails db:migrate`

---

## Related Documentation

- [Golf Courses API](./API_DOCUMENTATION_GOLF_COURSES.md) *(if exists)*
- [Group Invitations API](./API_DOCUMENTATION_GROUP_INVITATIONS.md)
- [Tee Time Postings API](./API_DOCUMENTATION_TEE_TIME_POSTINGS.md)
- [Users API](./API_DOCUMENTATION_USERS.md)
