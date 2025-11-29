# Group Invitations API Documentation

## Overview

Group invitations allow group owners and admins to invite users to join their groups via email. Users can accept or reject invitations they receive.

## Endpoints

### 1. Get User's Invitations

Get all pending invitations for the current user's email address.

```bash
GET /api/v1/group_invitations
```

**Headers:**
- `Authorization: Bearer <token>`

**Response:**
```json
{
  "group_invitations": [
    {
      "id": 1,
      "group_id": 2,
      "inviter_id": 1,
      "invitee_email": "user@example.com",
      "status": "pending",
      "created_at": "2024-11-29T12:00:00Z",
      "updated_at": "2024-11-29T12:00:00Z"
    }
  ]
}
```

### 2. Get Specific Invitation

Get details of a specific invitation.

```bash
GET /api/v1/group_invitations/:id
```

**Headers:**
- `Authorization: Bearer <token>`

**Response:**
```json
{
  "group_invitation": {
    "id": 1,
    "group_id": 2,
    "inviter_id": 1,
    "invitee_email": "user@example.com",
    "status": "pending",
    "created_at": "2024-11-29T12:00:00Z",
    "updated_at": "2024-11-29T12:00:00Z"
  }
}
```

### 3. Get Group's Invitations

Get all invitations sent for a specific group (owner/admin only).

```bash
GET /api/v1/groups/:group_id/invitations
```

**Headers:**
- `Authorization: Bearer <token>`

**Response:**
```json
{
  "group_invitations": [
    {
      "id": 1,
      "group_id": 2,
      "inviter_id": 1,
      "invitee_email": "user@example.com",
      "status": "pending",
      "created_at": "2024-11-29T12:00:00Z",
      "updated_at": "2024-11-29T12:00:00Z"
    },
    {
      "id": 2,
      "group_id": 2,
      "inviter_id": 1,
      "invitee_email": "another@example.com",
      "status": "accepted",
      "created_at": "2024-11-28T12:00:00Z",
      "updated_at": "2024-11-28T14:30:00Z"
    }
  ]
}
```

### 4. Create Invitation

Send an invitation to join a group (owner/admin only).

```bash
POST /api/v1/groups/:group_id/invitations
```

**Headers:**
- `Authorization: Bearer <token>`
- `Content-Type: application/json`

**Request Body:**
```json
{
  "group_invitation": {
    "invitee_email": "friend@example.com"
  }
}
```

**Response (201 Created):**
```json
{
  "group_invitation": {
    "id": 3,
    "group_id": 2,
    "inviter_id": 1,
    "invitee_email": "friend@example.com",
    "status": "pending",
    "created_at": "2024-11-29T12:00:00Z",
    "updated_at": "2024-11-29T12:00:00Z"
  }
}
```

### 5. Accept Invitation

Accept a pending invitation (creates group membership).

```bash
POST /api/v1/group_invitations/:id/accept
```

**Headers:**
- `Authorization: Bearer <token>`

**Response (200 OK):**
```json
{
  "group_invitation": {
    "id": 1,
    "group_id": 2,
    "inviter_id": 1,
    "invitee_email": "user@example.com",
    "status": "accepted",
    "created_at": "2024-11-29T12:00:00Z",
    "updated_at": "2024-11-29T12:30:00Z"
  },
  "message": "Successfully joined the group"
}
```

### 6. Reject Invitation

Reject a pending invitation.

```bash
POST /api/v1/group_invitations/:id/reject
```

**Headers:**
- `Authorization: Bearer <token>`

**Response (200 OK):**
```json
{
  "group_invitation": {
    "id": 1,
    "group_id": 2,
    "inviter_id": 1,
    "invitee_email": "user@example.com",
    "status": "rejected",
    "created_at": "2024-11-29T12:00:00Z",
    "updated_at": "2024-11-29T12:30:00Z"
  },
  "message": "Invitation rejected"
}
```

## Authorization Rules

- **View invitations**: Users can view invitations sent to their email address
- **View group invitations**: Group owners and admins can view all invitations for their groups
- **Create invitations**: Only group owners and admins can send invitations
- **Accept invitations**: Users can only accept invitations sent to their email address
- **Reject invitations**: Users can only reject invitations sent to their email address

## Validations

- Email must be valid format
- Cannot send duplicate pending invitations to the same email for the same group
- Can only accept/reject invitations with status "pending"
- Accepting an invitation automatically creates a group membership

## Example cURL Commands

### Get my invitations
```bash
curl -X GET http://localhost:3000/api/v1/group_invitations \
  -H "Authorization: Bearer $TOKEN"
```

### Send an invitation
```bash
curl -X POST http://localhost:3000/api/v1/groups/1/invitations \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "group_invitation": {
      "invitee_email": "friend@example.com"
    }
  }'
```

### Accept an invitation
```bash
curl -X POST http://localhost:3000/api/v1/group_invitations/1/accept \
  -H "Authorization: Bearer $TOKEN"
```

### Reject an invitation
```bash
curl -X POST http://localhost:3000/api/v1/group_invitations/1/reject \
  -H "Authorization: Bearer $TOKEN"
```

## Status Values

- `pending`: Invitation sent but not yet responded to
- `accepted`: User accepted and joined the group
- `rejected`: User declined the invitation

## Notes

- Tokens are generated automatically and are not exposed in API responses for security
- Future enhancement: Email notifications when invitations are sent (TODO)
- Invitations remain in the database for historical tracking even after being accepted/rejected
