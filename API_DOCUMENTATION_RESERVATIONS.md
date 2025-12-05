# Reservations API Documentation

## Overview

The Reservations API allows users to reserve spots on tee time postings. When a user makes a reservation, the available spots are dynamically calculated to reflect the current state. Posting owners can view who has reserved spots on their postings.

## Key Features

- **Dynamic Spot Calculation**: Available spots are calculated in real-time based on total_spots minus reserved spots
- **Owner Visibility**: Only the posting owner can see who has reserved spots
- **Privacy**: Regular users cannot see other users' reservations
- **Validation**: Prevents over-booking and duplicate reservations

## Reservation Model

```json
{
  "id": 1,
  "user_id": 5,
  "tee_time_posting_id": 10,
  "spots_reserved": 2,
  "created_at": "2024-12-01T14:30:00Z",
  "updated_at": "2024-12-01T14:30:00Z"
}
```

## TeeTimePosting with Reservations

### Owner View
When the authenticated user is the posting owner, the response includes a `reservations` array with all reservations:

```json
{
  "id": 10,
  "user_id": 1,
  "course_name": "Pebble Beach",
  "tee_time": "2024-12-15T10:00:00Z",
  "available_spots": 2,
  "total_spots": 4,
  "notes": "Looking for 2 more players",
  "group_ids": [1, 2],
  "created_at": "2024-12-01T12:00:00Z",
  "updated_at": "2024-12-01T12:00:00Z",
  "reservations": [
    {
      "id": 1,
      "user_email": "player1@example.com",
      "spots_reserved": 1,
      "created_at": "2024-12-01T14:00:00Z"
    },
    {
      "id": 2,
      "user_email": "player2@example.com",
      "spots_reserved": 1,
      "created_at": "2024-12-01T14:30:00Z"
    }
  ]
}
```

### Non-Owner View (With Reservation)
When a non-owner has a reservation, they can see **only their own reservation**:

```json
{
  "id": 10,
  "user_id": 1,
  "course_name": "Pebble Beach",
  "tee_time": "2024-12-15T10:00:00Z",
  "available_spots": 2,
  "total_spots": 4,
  "notes": "Looking for 2 more players",
  "group_ids": [1, 2],
  "created_at": "2024-12-01T12:00:00Z",
  "updated_at": "2024-12-01T12:00:00Z",
  "reservations": [
    {
      "id": 3,
      "user_id": 5,
      "user_email": "myemail@example.com",
      "spots_reserved": 1,
      "created_at": "2024-12-01T15:00:00Z"
    }
  ]
}
```

This allows users to see and manage their own reservations on the detail view.

## Endpoints

### 1. Create Reservation

Reserve spots on a tee time posting.

```bash
POST /api/v1/reservations
```

**Headers:**
- `Authorization: Bearer <token>`
- `Content-Type: application/json`

**Request Body:**
```json
{
  "reservation": {
    "tee_time_posting_id": 10,
    "spots_reserved": 2
  }
}
```

**Response (201 Created):**
```json
{
  "reservation": {
    "id": 1,
    "user_id": 5,
    "tee_time_posting_id": 10,
    "spots_reserved": 2,
    "created_at": "2024-12-01T14:30:00Z",
    "updated_at": "2024-12-01T14:30:00Z"
  }
}
```

**Error Responses:**

- `422 Unprocessable Entity` - Exceeds available spots
```json
{
  "errors": {
    "spots_reserved": ["cannot exceed available spots on the tee time posting"]
  }
}
```

- `422 Unprocessable Entity` - Already reserved
```json
{
  "errors": {
    "user_id": ["has already reserved this tee time"]
  }
}
```

### 2. Get My Reservations

Get all reservations made by the authenticated user.

```bash
GET /api/v1/reservations/my_reservations
```

**Headers:**
- `Authorization: Bearer <token>`

**Response (200 OK):**
```json
{
  "reservations": [
    {
      "id": 1,
      "user_id": 5,
      "tee_time_posting_id": 10,
      "spots_reserved": 2,
      "created_at": "2024-12-01T14:30:00Z",
      "updated_at": "2024-12-01T14:30:00Z"
    }
  ]
}
```

### 3. Update Reservation

Update the number of spots reserved (reserver only).

```bash
PATCH /api/v1/reservations/:id
```

**Headers:**
- `Authorization: Bearer <token>`
- `Content-Type: application/json`

**Request Body:**
```json
{
  "reservation": {
    "spots_reserved": 3
  }
}
```

**Response (200 OK):**
```json
{
  "reservation": {
    "id": 1,
    "user_id": 5,
    "tee_time_posting_id": 10,
    "spots_reserved": 3,
    "created_at": "2024-12-01T14:30:00Z",
    "updated_at": "2024-12-01T15:00:00Z"
  }
}
```

**Important Notes:**
- When updating a reservation, the validation accounts for your current reservation
- Example: If you have 2 spots reserved and there are 2 available, you can update to 4 total
- Calculation: `new_spots <= (available_spots + current_spots_reserved)`

**Error Responses:**

- `403 Forbidden` - Not the reserver
```json
{
  "error": "You are not authorized to perform this action"
}
```

- `422 Unprocessable Entity` - Exceeds available spots
```json
{
  "errors": {
    "spots_reserved": ["cannot exceed available spots on the tee time posting"]
  }
}
```

**Example Update Scenario:**
- Tee time has 4 total spots
- You currently have 2 spots reserved
- Available spots shows 2 (4 total - 2 yours)
- You can update to 4 spots (2 available + 2 yours = 4)
- You cannot update to 5 spots (would exceed total)

### 4. Delete Reservation

Cancel a reservation. Can be done by either the reserver or the posting owner.

```bash
DELETE /api/v1/reservations/:id
```

**Headers:**
- `Authorization: Bearer <token>`

**Response (204 No Content):**
No response body.

**Error Responses:**

- `403 Forbidden` - Not authorized
```json
{
  "error": "You are not authorized to perform this action"
}
```

- `404 Not Found` - Reservation not found
```json
{
  "error": "Reservation not found"
}
```

## Dynamic Available Spots Calculation

The `available_spots` field in tee time postings is calculated dynamically:

```
available_spots = total_spots - SUM(reservations.spots_reserved)
```

**Example:**
- Total spots: 4
- Reservation 1: 2 spots
- Reservation 2: 1 spot
- **Available spots: 1** (4 - 2 - 1)

This ensures the spot count is always accurate and prevents race conditions.

## Authorization Rules

- **Create reservation**: Any authenticated user can reserve available spots
- **View reservations**: Only the posting owner can see reservation details
- **Update reservation**: Only the reserver can update their reservation
- **Delete reservation**: Both the reserver and the posting owner can cancel

## Validation Rules

1. **Unique reservation per user**: Each user can only have one reservation per tee time posting
2. **Spot availability**:
   - For new reservations: Cannot reserve more spots than currently available
   - For updates: Cannot exceed `available_spots + your_current_spots_reserved`
3. **Positive spots**: Must reserve at least 1 spot
4. **Integer spots**: Spots must be whole numbers
5. **Total spots limit**: Cannot exceed the tee time's total_spots

## Example cURL Commands

### Create a reservation
```bash
curl -X POST http://localhost:3000/api/v1/reservations \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reservation": {
      "tee_time_posting_id": 10,
      "spots_reserved": 2
    }
  }'
```

### Get my reservations
```bash
curl -X GET http://localhost:3000/api/v1/reservations/my_reservations \
  -H "Authorization: Bearer $TOKEN"
```

### Update reservation
```bash
curl -X PATCH http://localhost:3000/api/v1/reservations/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reservation": {
      "spots_reserved": 1
    }
  }'
```

### Cancel reservation
```bash
curl -X DELETE http://localhost:3000/api/v1/reservations/1 \
  -H "Authorization: Bearer $TOKEN"
```

### Get tee time posting (as owner, includes reservations)
```bash
curl -X GET http://localhost:3000/api/v1/tee_time_postings/10 \
  -H "Authorization: Bearer $TOKEN"
```

## Privacy and Security

### What Posting Owners See
Posting owners can see:
- Email addresses of users who reserved
- Number of spots each user reserved
- When each reservation was made

### What Regular Users See
Regular users (non-owners) see:
- Total available spots
- Their own reservation (if they have one)
- **Cannot see** other users' reservations
- Can update or cancel their own reservation

### Example Scenarios

**Scenario 1: Owner Views Their Posting**
```json
{
  "tee_time_posting": {
    "id": 10,
    "available_spots": 1,
    "total_spots": 4,
    "reservations": [
      {
        "id": 1,
        "user_email": "alice@example.com",
        "spots_reserved": 2
      },
      {
        "id": 2,
        "user_email": "bob@example.com",
        "spots_reserved": 1
      }
    ]
  }
}
```

**Scenario 2: Non-Owner Without Reservation Views Same Posting**
```json
{
  "tee_time_posting": {
    "id": 10,
    "available_spots": 1,
    "total_spots": 4
    // No reservations array
  }
}
```

**Scenario 3: Non-Owner With Reservation Views Same Posting**
```json
{
  "tee_time_posting": {
    "id": 10,
    "available_spots": 1,
    "total_spots": 4,
    "reservations": [
      {
        "id": 3,
        "user_id": 5,
        "user_email": "myemail@example.com",
        "spots_reserved": 1
      }
    ]
    // Only shows their own reservation, not others
  }
}
```

## Common Use Cases

### 1. User Reserves Spots
1. User browses available tee times
2. User sees "2 spots available"
3. User creates reservation for 1 spot
4. System validates availability
5. Reservation created, available spots now shows 1

### 2. Posting Owner Manages Tee Time
1. Owner creates posting with 4 total spots
2. Three users reserve: 2, 1, and 1 spots
3. Owner views posting and sees all three reservations with email addresses
4. Owner can cancel any reservation if needed
5. Available spots automatically updates to 0

### 3. User Cancels Reservation
1. User views their reservations
2. User deletes a reservation
3. Spots become available again
4. Other users can now reserve those spots

## Best Practices

1. **Check availability**: Always check `available_spots` before attempting to reserve
2. **Handle validation errors**: Be prepared for "exceeds available spots" errors
3. **Refresh after actions**: Reload tee time data after creating/deleting reservations
4. **Owner notifications**: Consider implementing notifications when users reserve spots
5. **Cancellation policy**: Communicate cancellation rules to users

## Future Enhancements

### Reservation Confirmation
- Add confirmation step before finalizing reservation
- Show posting details and reservation summary

### Waitlist System
- Allow users to join waitlist when fully booked
- Automatically notify waitlisted users when spots become available

### Reservation Notes
- Allow users to add notes to their reservations
- Useful for communicating skill level, preferences, etc.

### Expiration
- Automatically cancel reservations if tee time has passed
- Send reminders before tee time

### Bulk Operations
- Allow posting owners to cancel all reservations
- Useful when canceling a tee time posting

## Recent Changes

### December 2025 - Reservation Management Improvements

**Non-Owner Reservation Visibility**
- Non-owners can now see their own reservation when viewing tee time details
- Enables users to update or cancel their reservations directly from the detail view
- Privacy maintained: users still cannot see other users' reservations

**Improved Update Validation**
- Reservation updates now account for the user's current reservation
- Users can increase their reservation up to `available_spots + current_spots_reserved`
- Example: With 2 spots reserved and 2 available, can update to 4 total
- Prevents unnecessary validation errors when managing reservations

**Database Schema**
- `available_spots` column made nullable with default value of 0
- Column still exists for backward compatibility but value is always calculated dynamically
- Migration: `20251205041214_change_available_spots_to_nullable.rb`
