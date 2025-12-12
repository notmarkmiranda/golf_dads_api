# Group Invite Codes API Documentation

## Overview

Groups use invite codes for sharing and joining. Each group has a unique, regeneratable 8-character alphanumeric code that can be shared via any channel (text, social media, etc.). No email infrastructure required!

## Group Model

Every `Group` includes an `invite_code` field:

```json
{
  "id": 1,
  "name": "Weekend Warriors",
  "description": "Saturday morning golf",
  "owner_id": 5,
  "invite_code": "ABC12XYZ",
  "created_at": "2024-11-29T12:00:00Z",
  "updated_at": "2024-11-29T12:00:00Z"
}
```

## Endpoints

### 1. Get Group Details (includes invite code)

Get group information including the invite code.

```bash
GET /api/v1/groups/:id
```

**Headers:**
- `Authorization: Bearer <token>`

**Response:**
```json
{
  "group": {
    "id": 1,
    "name": "Weekend Warriors",
    "description": "Saturday morning golf",
    "owner_id": 5,
    "invite_code": "ABC12XYZ",
    "created_at": "2024-11-29T12:00:00Z",
    "updated_at": "2024-11-29T12:00:00Z"
  }
}
```

### 2. Regenerate Invite Code

Generate a new invite code for the group (owner only). Useful if the code has been leaked or shared publicly.

```bash
POST /api/v1/groups/:id/regenerate_code
```

**Headers:**
- `Authorization: Bearer <token>`

**Response (200 OK):**
```json
{
  "group": {
    "id": 1,
    "name": "Weekend Warriors",
    "description": "Saturday morning golf",
    "owner_id": 5,
    "invite_code": "NEW8CODE",
    "created_at": "2024-11-29T12:00:00Z",
    "updated_at": "2024-11-29T13:00:00Z"
  },
  "message": "Invite code regenerated successfully"
}
```

### 3. Get Group Tee Time Postings

Get all tee time postings for a specific group.

```bash
GET /api/v1/groups/:id/tee_time_postings
```

**Headers:**
- `Authorization: Bearer <token>`

**Response (200 OK):**
```json
{
  "tee_time_postings": [
    {
      "id": 1,
      "user_id": 5,
      "course_name": "Pebble Beach",
      "tee_time": "2024-12-15T10:00:00Z",
      "available_spots": 2,
      "total_spots": 4,
      "notes": "Looking for 2 more players",
      "created_at": "2024-11-29T12:00:00Z",
      "updated_at": "2024-11-29T12:00:00Z"
    }
  ]
}
```

**Error Responses:**

- `404 Not Found` - Group not found
```json
{
  "error": "Group not found"
}
```

- `403 Forbidden` - User is not authorized to view the group
```json
{
  "error": "You are not authorized to view this group"
}
```

### 4. Join Group with Invite Code

Join a group using its invite code.

```bash
POST /api/v1/groups/join_with_code
```

**Headers:**
- `Authorization: Bearer <token>`
- `Content-Type: application/json`

**Request Body:**
```json
{
  "invite_code": "ABC12XYZ"
}
```

**Response (200 OK):**
```json
{
  "group": {
    "id": 1,
    "name": "Weekend Warriors",
    "description": "Saturday morning golf",
    "owner_id": 5,
    "invite_code": "ABC12XYZ",
    "created_at": "2024-11-29T12:00:00Z",
    "updated_at": "2024-11-29T12:00:00Z"
  },
  "message": "Successfully joined Weekend Warriors"
}
```

**Error Responses:**

- `400 Bad Request` - Invite code is missing
```json
{
  "error": "Invite code is required"
}
```

- `404 Not Found` - Invalid invite code
```json
{
  "error": "Invalid invite code"
}
```

- `422 Unprocessable Entity` - Already a member
```json
{
  "error": "You are already a member of this group"
}
```

### 5. Leave Group

Leave a group you're a member of (except group owner - owner must transfer ownership first).

```bash
POST /api/v1/groups/:id/leave
```

**Headers:**
- `Authorization: Bearer <token>`

**Response (200 OK):**
```json
{
  "message": "Successfully left the group"
}
```

**Error Responses:**

- `403 Forbidden` - User is the group owner (must transfer ownership first)
```json
{
  "error": "Owner must transfer ownership before leaving"
}
```

- `403 Forbidden` - User is not a member of the group
```json
{
  "error": "You are not authorized to perform this action"
}
```

- `404 Not Found` - Group not found
```json
{
  "error": "Group not found"
}
```

- `401 Unauthorized` - Not authenticated
```json
{
  "error": "Unauthorized"
}
```

### 6. Remove Member from Group

Remove a member from the group (owner only). Owner cannot be removed.

```bash
DELETE /api/v1/groups/:id/members/:user_id
```

**Headers:**
- `Authorization: Bearer <token>`

**URL Parameters:**
- `id` - Group ID
- `user_id` - User ID of the member to remove

**Response (200 OK):**
```json
{
  "message": "Member removed successfully"
}
```

**Error Responses:**

- `422 Unprocessable Entity` - Attempting to remove the group owner
```json
{
  "error": "Cannot remove the group owner"
}
```

- `422 Unprocessable Entity` - User is not a member
```json
{
  "error": "User is not a member of this group"
}
```

- `404 Not Found` - User not found
```json
{
  "error": "User not found"
}
```

- `403 Forbidden` - User is not the group owner
```json
{
  "error": "You are not authorized to perform this action"
}
```

- `404 Not Found` - Group not found
```json
{
  "error": "Group not found"
}
```

- `401 Unauthorized` - Not authenticated
```json
{
  "error": "Unauthorized"
}
```

## Authorization Rules

- **View invite code**: Group members can view the invite code
- **Regenerate invite code**: Only group owners can regenerate the code
- **Join with code**: Any authenticated user can join a group if they have the valid invite code
- **Leave group**: Any group member can leave, except the owner (owner must transfer ownership first)
- **Remove member**: Only the group owner can remove members (cannot remove the owner)

## Invite Code Properties

- **Format**: 8-character alphanumeric string (uppercase)
- **Example**: `ABC12XYZ`, `K9L4MN23`
- **Uniqueness**: Guaranteed unique across all groups
- **Case-insensitive**: Lookups work regardless of case (code is stored in uppercase)
- **Auto-generated**: Created automatically when a group is created
- **Regeneratable**: Can be changed by the group owner at any time

## Example cURL Commands

### Get group with invite code
```bash
curl -X GET http://localhost:3000/api/v1/groups/1 \
  -H "Authorization: Bearer $TOKEN"
```

### Regenerate invite code (owner only)
```bash
curl -X POST http://localhost:3000/api/v1/groups/1/regenerate_code \
  -H "Authorization: Bearer $TOKEN"
```

### Get group tee time postings
```bash
curl -X GET http://localhost:3000/api/v1/groups/1/tee_time_postings \
  -H "Authorization: Bearer $TOKEN"
```

### Join group with code
```bash
curl -X POST http://localhost:3000/api/v1/groups/join_with_code \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "invite_code": "ABC12XYZ"
  }'
```

### Leave group
```bash
curl -X POST http://localhost:3000/api/v1/groups/1/leave \
  -H "Authorization: Bearer $TOKEN"
```

### Remove member (owner only)
```bash
curl -X DELETE http://localhost:3000/api/v1/groups/1/members/5 \
  -H "Authorization: Bearer $TOKEN"
```

## Sharing Invite Codes

Group owners can share invite codes through any channel:

1. **Text message**: "Join our golf group! Code: ABC12XYZ"
2. **Social media**: Post the code for followers
3. **Email**: Include in email body
4. **QR code**: Generate QR code containing the invite code
5. **Deep link**: `golfapp://join?code=ABC12XYZ`

## Security Considerations

- **Regeneration**: If a code is leaked or shared too widely, owners can regenerate it
- **No email required**: Users don't need to share email addresses
- **Simple revocation**: Regenerating the code immediately invalidates the old one
- **Member tracking**: All group members are tracked via `GroupMembership` records

## Migration from Email Invitations

This system replaces the previous email-based invitation flow with a simpler, more flexible approach:

**Before** (Email Invitations):
- Owner sends invitation to specific email
- Invitee receives invitation
- Invitee accepts/rejects
- Email infrastructure required

**Now** (Invite Codes):
- Owner shares code via any channel
- Anyone with code can join
- No email infrastructure needed
- More viral/shareable

## Notes

- Invite codes are automatically generated when a group is created
- Codes remain valid until regenerated
- Joining a group automatically creates a `GroupMembership` record
- No limit on how many people can use the same code (until regenerated)

## Future Enhancements

### Group Preview/Lookup Endpoint

**Goal**: Allow users to preview group information before joining

**Proposed Endpoint**: `GET /api/v1/groups/lookup_by_code?invite_code=ABC123`

**Use Case**:
Currently, entering an invite code immediately joins the group. A lookup endpoint would allow users to:
- See group name and description before joining
- Check if they're already a member
- Make an informed decision before committing

**Response Format**:
```json
{
  "group": {
    "id": 1,
    "name": "Weekend Warriors",
    "description": "Saturday morning golf",
    "owner_id": 5,
    "invite_code": "ABC12XYZ",
    "created_at": "2024-11-29T12:00:00Z",
    "updated_at": "2024-11-29T12:00:00Z"
  },
  "is_member": false,
  "member_count": 12
}
```

**Implementation Notes**:
- Should not require authentication for previewing public group info
- Returns 404 if invite code is invalid
- Can show membership status if user is authenticated
- Could optionally include member count for social proof
