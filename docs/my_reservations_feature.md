# My Reservations Feature

## Overview

The "My Reservations" feature allows users to view their reservations on tee time postings in a dedicated section, separate from tee time postings they've created.

## API Endpoints

### Get My Reservations

```
GET /api/v1/reservations/my_reservations
```

**Authentication**: Required

**Response**:
```json
{
  "reservations": [
    {
      "id": 34,
      "user_id": 13,
      "tee_time_posting_id": 33,
      "spots_reserved": 2,
      "created_at": "2025-12-10T02:01:51.000Z",
      "updated_at": "2025-12-10T02:01:51.000Z",
      "tee_time_posting": {
        "id": 33,
        "user_id": 13,
        "course_name": "Sunset Golf Course",
        "tee_time": "2025-12-11T01:54:18.000Z",
        "available_spots": 2,
        "total_spots": 4,
        "notes": null,
        "is_public": false,
        "is_past": false
      }
    }
  ]
}
```

## Backend Implementation

### Reservation Model Changes

**Added `tee_time_posting` details to `Reservation#as_json`:**

```ruby
def as_json(options = {})
  result = super(options)

  if tee_time_posting.present?
    result['tee_time_posting'] = {
      'id' => tee_time_posting.id,
      'user_id' => tee_time_posting.user_id,
      'course_name' => tee_time_posting.course_name,
      'tee_time' => tee_time_posting.tee_time,
      'available_spots' => tee_time_posting.available_spots,
      'total_spots' => tee_time_posting.total_spots,
      'notes' => tee_time_posting.notes,
      'is_public' => tee_time_posting.public?,
      'is_past' => tee_time_posting.past?
    }
  end

  result
end
```

**Why include `user_id`?** Allows the iOS app to determine if the user owns the posting and filter accordingly.

### Controller Changes

**Added eager loading in `ReservationsController`:**

```ruby
def my_reservations
  authorize Reservation
  @reservations = policy_scope(Reservation)
    .includes(:tee_time_posting)  # Prevents N+1 queries
    .where(user_id: current_user.id)
  render json: { reservations: @reservations }, status: :ok
end
```

### Policy Changes

**Added `my_reservations?` method to `ReservationPolicy`:**

```ruby
def my_reservations?
  user.present?
end
```

Allows any authenticated user to view their own reservations.

## iOS Implementation

### Models

**Added `ReservationTeeTimeInfo` struct:**

```swift
struct ReservationTeeTimeInfo: Codable, Equatable, Hashable {
    let id: Int
    let userId: Int          // Owner of the posting
    let courseName: String
    let teeTime: Date
    let availableSpots: Int
    let totalSpots: Int?
    let notes: String?
    let isPublic: Bool
    let isPast: Bool
}
```

**Updated `Reservation` to include posting info:**

```swift
struct Reservation: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let userId: Int
    let teeTimePostingId: Int
    let spotsReserved: Int
    let createdAt: Date
    let updatedAt: Date
    let teeTimePosting: ReservationTeeTimeInfo?
}
```

### UI Sections

**My Tee Times View** now shows two sections:

1. **My Postings**: Tee times you created where you DON'T have a reservation
2. **My Reservations**: All postings where you HAVE a reservation (including your own)

### Filtering Logic

```swift
// Get IDs of postings where user has a reservation
let postingIdsWithReservations = Set(
  newReservations.compactMap { $0.teeTimePosting?.id }
)

// Filter postings to exclude ones with reservations
teeTimePostings = newPostings.filter {
  !postingIdsWithReservations.contains($0.id)
}

// Show all reservations (including own postings)
myReservations = newReservations
```

## User Experience

### Scenario 1: User Creates Posting Without Reservation
- **My Postings**: ✅ Shows the posting
- **My Reservations**: ❌ Does not show

### Scenario 2: User Reserves on Someone Else's Posting
- **My Postings**: ❌ Does not show
- **My Reservations**: ✅ Shows the reservation

### Scenario 3: User Creates Posting AND Reserves Spots
- **My Postings**: ❌ Does not show (has reservation)
- **My Reservations**: ✅ Shows the reservation

### Scenario 4: User Cancels Their Reservation on Own Posting
- After cancellation:
  - Posting refreshes automatically
  - Moves from "My Reservations" to "My Postings"
  - Detail view stays open (doesn't auto-dismiss)

## Data Loading

### Parallel Loading

Both postings and reservations are loaded in parallel for performance:

```swift
async let postingsResult = teeTimeService.getMyTeeTimePostings()
async let reservationsResult = reservationService.getMyReservations()

let newPostings = await postingsResult
let newReservations = await reservationsResult
```

### Cancellation Handling

- Detects URLError -999 (cancelled) and handles gracefully
- Preserves existing data if refresh is cancelled
- Only clears data if both requests fail AND there's no existing data

### Task Management

- Tracks current load task to prevent concurrent loads
- Cancels previous task when starting new one
- Prevents race conditions between `.task`, `.refreshable`, and `.onChange`

## Edge Cases

### Orphaned Reservations

If a tee time posting is deleted but reservations still exist:

```ruby
# Backend handles gracefully
if tee_time_posting.present?
  result['tee_time_posting'] = { ... }
end
# If nil, tee_time_posting key is omitted
```

```swift
// iOS filters out reservations without posting info
myReservations = newReservations.filter {
  reservation.teeTimePosting != nil
}
```

### Network Errors

- URLError -999 (cancelled) is handled silently
- Other errors are logged and displayed to user
- Pull-to-refresh preserves existing data on error

### Empty States

Three possible empty states:
1. No postings, no reservations: Shows "Create your first tee time"
2. Has postings, no reservations: Shows only "My Postings" section
3. No postings, has reservations: Shows only "My Reservations" section

## Testing

All 371 backend tests pass, including:
- Reservation model tests
- Reservation controller tests
- Reservation policy tests
- Integration tests for my_reservations endpoint

iOS builds successfully with no errors or warnings.
