# User Profile API Documentation

This document describes the user profile management endpoints in the Golf Dads API.

## Endpoints

### Get Current User Profile

Retrieve the profile information for the authenticated user.

**Endpoint:** `GET /api/v1/users/me`

**Authentication:** Required (JWT token in Authorization header)

**Request Example:**
```bash
curl -X GET http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Success Response (200 OK):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "name": "John Doe",
  "avatar_url": "https://example.com/avatar.jpg",
  "provider": "google",
  "venmo_handle": "@johndoe",
  "handicap": "15.5"
}
```

**Error Responses:**

- **401 Unauthorized:** Missing or invalid authentication token
```json
{
  "error": "Unauthorized"
}
```

---

### Update User Profile

Update the profile information for the authenticated user. All fields are optional - only provided fields will be updated.

**Endpoint:** `PATCH /api/v1/users/me`

**Authentication:** Required (JWT token in Authorization header)

**Request Body:**
```json
{
  "user": {
    "name": "John Doe",
    "venmo_handle": "@johndoe",
    "handicap": 15.5
  }
}
```

**Field Descriptions:**

| Field | Type | Required | Description | Validation |
|-------|------|----------|-------------|------------|
| `name` | string | No | User's display name | Must not be blank |
| `venmo_handle` | string | No | Venmo username for payments | Must start with '@' (automatically added if missing) |
| `handicap` | number | No | Golf handicap index | Must be between 0 and 54.0, supports one decimal place |

**Request Examples:**

1. **Update venmo_handle:**
```bash
curl -X PATCH http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "venmo_handle": "johndoe"
    }
  }'
```

2. **Update handicap:**
```bash
curl -X PATCH http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "handicap": 27.5
    }
  }'
```

3. **Update multiple fields:**
```bash
curl -X PATCH http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "John Smith",
      "venmo_handle": "@jsmith",
      "handicap": 12.5
    }
  }'
```

**Success Response (200 OK):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "name": "John Smith",
  "avatar_url": "https://example.com/avatar.jpg",
  "provider": "google",
  "venmo_handle": "@jsmith",
  "handicap": "12.5"
}
```

**Error Responses:**

- **401 Unauthorized:** Missing or invalid authentication token
```json
{
  "error": "Unauthorized"
}
```

- **422 Unprocessable Content:** Validation errors
```json
{
  "errors": {
    "name": ["can't be blank"],
    "handicap": ["must be greater than or equal to 0"]
  }
}
```

---

## Field Details

### Venmo Handle

The `venmo_handle` field is automatically normalized:
- If you provide "johndoe", it becomes "@johndoe"
- If you provide "@johndoe", it stays "@johndoe"
- If you provide an empty string, it becomes `null`

**Validation Rules:**
- Must start with '@' (automatically added)
- Optional field (can be `null`)

**Examples:**
```json
// Input: "johndoe" → Stored as: "@johndoe"
// Input: "@johndoe" → Stored as: "@johndoe"
// Input: "" → Stored as: null
// Input: null → Stored as: null
```

### Handicap

The `handicap` field represents a golfer's handicap index.

**Validation Rules:**
- Must be a number between 0 and 54.0
- Supports one decimal place (e.g., 27.5)
- Optional field (can be `null`)

**Examples:**
```json
// Valid values:
0, 5, 10.5, 27.5, 54.0

// Invalid values:
-5 → Error: "must be greater than or equal to 0"
55 → Error: "must be less than or equal to 54.0"
"invalid" → Error: "is not a number"
```

---

## Authentication

All user profile endpoints require JWT authentication. Include the token in the Authorization header:

```
Authorization: Bearer YOUR_JWT_TOKEN
```

You can obtain a JWT token through:
- `POST /api/v1/auth/signup` - Create a new account
- `POST /api/v1/auth/login` - Login with email/password
- `POST /api/v1/auth/google` - Login with Google

---

## User Response Object

The user response object returned from profile endpoints includes:

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Unique user identifier |
| `email` | string | User's email address |
| `name` | string | User's display name |
| `avatar_url` | string or null | URL to user's avatar image |
| `provider` | string or null | OAuth provider ("google" or null for email/password users) |
| `venmo_handle` | string or null | User's Venmo handle (with @ prefix) |
| `handicap` | string or null | User's golf handicap as a decimal string |

**Note:** The `handicap` is returned as a string to preserve decimal precision (e.g., "15.5" instead of 15.5).

---

## Testing

### Manual Testing

1. **Login to get a token:**
```bash
TOKEN=$(curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}' \
  | jq -r '.token')
```

2. **Get current user:**
```bash
curl -X GET http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN"
```

3. **Update profile:**
```bash
curl -X PATCH http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"user":{"venmo_handle":"myhandle","handicap":15.5}}'
```

### Automated Tests

Run the test suite:
```bash
bundle exec rspec spec/requests/api/v1/users_spec.rb
```

---

## Notes

- Profile updates are immediate and do not require email confirmation
- The `email` field cannot be updated through this endpoint for security reasons
- The `provider` and `avatar_url` fields are read-only
- All profile fields except `name` are optional
- Partial updates are supported - only send the fields you want to change
