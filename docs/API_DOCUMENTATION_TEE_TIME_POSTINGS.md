# Tee Time Postings API Documentation

## Overview

The Tee Time Postings API allows users to create, view, update, and manage golf tee time postings. Tee times can be public (visible to all users) or private (visible only to specific groups).

## Base URL

- **Local Development:** `http://localhost:3000/api/v1`
- **Production:** `https://golf-dads-api.onrender.com/api/v1`

## Authentication

All endpoints require authentication using a JWT token in the Authorization header:

```
Authorization: Bearer YOUR_JWT_TOKEN
```

---

## Endpoints

### 1. List All Tee Time Postings

**Endpoint:** `GET /tee_time_postings`

Returns all tee time postings visible to the current user (public postings and postings from groups they belong to).

**Request:**
```bash
curl -X GET http://localhost:3000/api/v1/tee_time_postings \
  -H "Authorization: Bearer $TOKEN"
```

**Response:** `200 OK`
```json
{
  "tee_time_postings": [
    {
      "id": 1,
      "user_id": 1,
      "group_ids": [],
      "course_name": "Pebble Beach Golf Links",
      "tee_time": "2025-12-28T10:00:00.000Z",
      "available_spots": 3,
      "total_spots": 4,
      "notes": "Looking for players. Bring extra balls!",
      "created_at": "2025-12-04T10:00:00.000Z",
      "updated_at": "2025-12-04T10:00:00.000Z"
    }
  ]
}
```

**Notes:**
- `available_spots` is calculated dynamically as `total_spots - sum(reservations)`
- `group_ids` is empty for public postings
- Only upcoming tee times are returned based on policy scope

---

### 2. Get Specific Tee Time Posting

**Endpoint:** `GET /tee_time_postings/:id`

Returns details for a specific tee time posting.

**Request:**
```bash
curl -X GET http://localhost:3000/api/v1/tee_time_postings/1 \
  -H "Authorization: Bearer $TOKEN"
```

**Response:** `200 OK`
```json
{
  "tee_time_posting": {
    "id": 1,
    "user_id": 1,
    "group_ids": [],
    "course_name": "Pebble Beach Golf Links",
    "tee_time": "2025-12-28T10:00:00.000Z",
    "available_spots": 3,
    "total_spots": 4,
    "notes": "Looking for players. Bring extra balls!",
    "created_at": "2025-12-04T10:00:00.000Z",
    "updated_at": "2025-12-04T10:00:00.000Z",
    "reservations": [
      {
        "id": 1,
        "user_id": 1,
        "user_email": "owner@example.com",
        "spots_reserved": 1,
        "created_at": "2025-12-04T10:00:00.000Z"
      }
    ]
  }
}
```

**Notes:**
- `reservations` array is only included if the current user is the owner of the posting
- Useful for viewing who has reserved spots on your tee time

**Error Responses:**
- `404 Not Found` - Tee time posting doesn't exist
- `403 Forbidden` - User doesn't have permission to view this posting

---

### 3. Create Tee Time Posting

**Endpoint:** `POST /tee_time_postings`

Creates a new tee time posting.

**Request:**
```bash
curl -X POST http://localhost:3000/api/v1/tee_time_postings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tee_time_posting": {
      "course_name": "Pebble Beach Golf Links",
      "tee_time": "2025-12-28T10:00:00Z",
      "total_spots": 4,
      "notes": "Looking for players. Bring extra balls!",
      "group_ids": []
    },
    "initial_reservation_spots": 1
  }'
```

**Request Body Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `course_name` | string | Yes | Name of the golf course |
| `tee_time` | datetime | Yes | ISO 8601 formatted date/time in the future |
| `total_spots` | integer | Yes | Total number of spots (1-4) |
| `notes` | string | No | Additional notes or details |
| `group_ids` | array | No | Array of group IDs (empty for public posting) |
| `initial_reservation_spots` | integer | No | Number of spots to reserve for yourself (0-3) |

**Response:** `201 Created`
```json
{
  "tee_time_posting": {
    "id": 2,
    "user_id": 1,
    "group_ids": [],
    "course_name": "Pebble Beach Golf Links",
    "tee_time": "2025-12-28T10:00:00.000Z",
    "available_spots": 3,
    "total_spots": 4,
    "notes": "Looking for players. Bring extra balls!",
    "created_at": "2025-12-04T10:05:00.000Z",
    "updated_at": "2025-12-04T10:05:00.000Z",
    "reservations": [
      {
        "id": 5,
        "user_id": 1,
        "user_email": "owner@example.com",
        "spots_reserved": 1,
        "created_at": "2025-12-04T10:05:00.000Z"
      }
    ]
  }
}
```

**Notes:**
- If `initial_reservation_spots` is provided, a reservation is automatically created for the current user
- `available_spots` reflects the calculation: `total_spots - initial_reservation_spots`
- Tee time must be in the future
- If `group_ids` is empty, the posting is public
- Transaction ensures both posting and reservation are created atomically

**Error Responses:**
- `422 Unprocessable Entity` - Validation errors
  ```json
  {
    "status": 422,
    "error": "Unprocessable Entity",
    "messages": {
      "tee_time": ["must be in the future"],
      "course_name": ["can't be blank"]
    }
  }
  ```

---

### 4. Update Tee Time Posting

**Endpoint:** `PATCH /tee_time_postings/:id`

Updates an existing tee time posting. Only the owner can update their posting.

**Request:**
```bash
curl -X PATCH http://localhost:3000/api/v1/tee_time_postings/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tee_time_posting": {
      "notes": "Updated notes - please arrive 15 minutes early"
    }
  }'
```

**Updatable Fields:**
- `course_name` - Course name
- `tee_time` - Date/time (only if posting hasn't started yet)
- `total_spots` - Total spots (must be >= current reservations)
- `notes` - Notes
- `group_ids` - Group visibility

**Response:** `200 OK`
```json
{
  "tee_time_posting": {
    "id": 1,
    "user_id": 1,
    "group_ids": [],
    "course_name": "Pebble Beach Golf Links",
    "tee_time": "2025-12-28T10:00:00.000Z",
    "available_spots": 3,
    "total_spots": 4,
    "notes": "Updated notes - please arrive 15 minutes early",
    "created_at": "2025-12-04T10:00:00.000Z",
    "updated_at": "2025-12-04T10:10:00.000Z"
  }
}
```

**Error Responses:**
- `403 Forbidden` - User is not the owner
- `404 Not Found` - Tee time posting doesn't exist
- `422 Unprocessable Entity` - Validation errors

---

### 5. Delete Tee Time Posting

**Endpoint:** `DELETE /tee_time_postings/:id`

Deletes a tee time posting. Only the owner can delete their posting.

**Request:**
```bash
curl -X DELETE http://localhost:3000/api/v1/tee_time_postings/1 \
  -H "Authorization: Bearer $TOKEN"
```

**Response:** `204 No Content`

**Notes:**
- All associated reservations are also deleted (cascade delete)

**Error Responses:**
- `403 Forbidden` - User is not the owner
- `404 Not Found` - Tee time posting doesn't exist

---

### 6. Get My Tee Time Postings

**Endpoint:** `GET /tee_time_postings/my_postings`

Returns all tee time postings created by the current user.

**Request:**
```bash
curl -X GET http://localhost:3000/api/v1/tee_time_postings/my_postings \
  -H "Authorization: Bearer $TOKEN"
```

**Response:** `200 OK`
```json
{
  "tee_time_postings": [
    {
      "id": 1,
      "user_id": 1,
      "group_ids": [],
      "course_name": "Pebble Beach Golf Links",
      "tee_time": "2025-12-28T10:00:00.000Z",
      "available_spots": 3,
      "total_spots": 4,
      "notes": "Looking for players",
      "created_at": "2025-12-04T10:00:00.000Z",
      "updated_at": "2025-12-04T10:00:00.000Z"
    }
  ]
}
```

---

## Data Model

### TeeTimePosting

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Unique identifier |
| `user_id` | integer | ID of the user who created the posting |
| `course_name` | string | Name of the golf course |
| `tee_time` | datetime | Date and time of the tee time |
| `total_spots` | integer | Total number of spots available (1-4) |
| `available_spots` | integer | Calculated: `total_spots - sum(reservations.spots_reserved)` |
| `notes` | text | Optional notes or description |
| `group_ids` | array | Array of group IDs for private postings |
| `created_at` | datetime | When the posting was created |
| `updated_at` | datetime | When the posting was last updated |

### Reservations (nested in owner's view)

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Unique identifier |
| `user_id` | integer | ID of the user who made the reservation |
| `user_email` | string | Email of the user who made the reservation |
| `spots_reserved` | integer | Number of spots reserved |
| `created_at` | datetime | When the reservation was created |

---

## Business Rules

1. **Available Spots Calculation**
   - Always calculated dynamically as `total_spots - sum(reservations.spots_reserved)`
   - Never manually set by users
   - Ensures consistency across the system

2. **Tee Time Creation**
   - Tee time must be in the future
   - User can optionally reserve spots for themselves immediately
   - Initial reservation is created in the same transaction

3. **Visibility**
   - Public postings (`group_ids: []`) are visible to all authenticated users
   - Private postings are only visible to group members

4. **Permissions**
   - Only the owner can update or delete their posting
   - Only the owner can see the list of reservations

5. **Reservations**
   - See [API_DOCUMENTATION_RESERVATIONS.md](API_DOCUMENTATION_RESERVATIONS.md) for reservation management

---

## Example Workflows

### Creating a Public Tee Time

```bash
# Create a public tee time with 4 total spots, reserving 1 for yourself
curl -X POST http://localhost:3000/api/v1/tee_time_postings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tee_time_posting": {
      "course_name": "Augusta National",
      "tee_time": "2025-12-28T09:00:00Z",
      "total_spots": 4,
      "notes": "Anyone want to join?",
      "group_ids": []
    },
    "initial_reservation_spots": 1
  }'
# Result: Posting created with 3 available spots (4 total - 1 reserved)
```

### Creating a Private Group Tee Time

```bash
# Create a tee time visible only to groups 1 and 2
curl -X POST http://localhost:3000/api/v1/tee_time_postings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tee_time_posting": {
      "course_name": "Private Country Club",
      "tee_time": "2025-12-28T14:00:00Z",
      "total_spots": 4,
      "group_ids": [1, 2]
    }
  }'
# Result: Posting created with 4 available spots, visible only to groups 1 & 2
```

### Creating Without Reserving Spots

```bash
# Create a tee time without reserving any spots for yourself
curl -X POST http://localhost:3000/api/v1/tee_time_postings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tee_time_posting": {
      "course_name": "Local Municipal Course",
      "tee_time": "2025-12-29T08:00:00Z",
      "total_spots": 3
    }
  }'
# Result: Posting created with all 3 spots available
```

---

## Testing

### Quick Test with HTTPie

```bash
# Install httpie
brew install httpie

# Create a tee time
http POST localhost:3000/api/v1/tee_time_postings \
  "Authorization: Bearer $TOKEN" \
  tee_time_posting:='{"course_name":"Test Course","tee_time":"2025-12-30T10:00:00Z","total_spots":4}' \
  initial_reservation_spots:=2

# List all tee times
http GET localhost:3000/api/v1/tee_time_postings \
  "Authorization: Bearer $TOKEN"

# Get specific tee time
http GET localhost:3000/api/v1/tee_time_postings/1 \
  "Authorization: Bearer $TOKEN"
```

---

## Related Documentation

- [Reservations API](API_DOCUMENTATION_RESERVATIONS.md)
- [Groups API](API_DOCUMENTATION_GROUPS.md)
- [Users API](API_DOCUMENTATION_USERS.md)
