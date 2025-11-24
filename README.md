# Golf Dads API

A Rails API for sharing available tee time spots with golf groups and the wider community.

## Project Overview

This API serves as the backend for an iOS application that allows golfers to post available spots on tee times to their groups or the public community.

## Tech Stack

### Core Framework
- **Rails 8.1.1** (API-only mode)
- **Ruby** (version in `.ruby-version`)
- **PostgreSQL** - Primary database

### Authentication & Authorization
- **Rails 8 Authentication** - Built-in `has_secure_password` with bcrypt
- **JWT** - Token-based authentication for API (24-hour expiration)
- **Google OAuth** - Server-side token verification for Google Sign-In
- **Pundit** (installed) - Authorization policies

### API & Serialization
- **JSONAPI Serializer** - JSON API-compliant response formatting
- **Rack-CORS** - Cross-Origin Resource Sharing for iOS app

### Testing (TDD)
- **RSpec** - Test framework
- **FactoryBot** - Test data factories
- **Shoulda Matchers** - Concise model testing
- **Faker** - Realistic test data generation
- **Database Cleaner** - Test database isolation

### Admin Interface
- **Avo** - Modern admin dashboard for data management

## Setup Instructions

### Prerequisites
- Ruby (see `.ruby-version`)
- PostgreSQL 14+
- Bundler

### Installation

1. Clone the repository and navigate to the project:
```bash
cd golf_api
```

2. Install dependencies:
```bash
bundle install
```

3. Configure database:
```bash
# Ensure PostgreSQL is running
brew services start postgresql@14

# Create databases
rails db:create

# Run migrations (when available)
rails db:migrate
```

### Running Tests

```bash
# Run entire test suite
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run with documentation format
bundle exec rspec --format documentation
```

### Development Server

```bash
rails server
# API will be available at http://localhost:3000
```

### Admin Dashboard

The Avo admin dashboard is protected with HTTP Basic Authentication:
```
http://localhost:3000/avo
```

**Default Credentials (Development):**
- Username: `admin`
- Password: `changeme`

**Production Setup:**
Set environment variables:
```bash
export AVO_USERNAME=your_admin_username
export AVO_PASSWORD=your_secure_password
```

**Managing Admin Users:**
```bash
# Promote a user to admin (for future session-based Avo auth)
rails admin:promote[user@example.com]

# Remove admin privileges
rails admin:demote[user@example.com]

# List all admin users
rails admin:list
```

## Execution Plan

This project is being built in **5 phases** with **33 total steps** using Test-Driven Development (TDD).

**Progress Overview:**
- ✅ **Phase 1:** Foundation (6/6 steps) - **100% Complete**
- 🚧 **Phase 2:** Core Models with TDD (14/15 steps) - **93% Complete** ← Current Phase
- ⏳ **Phase 3:** Authorization (0/5 steps) - **0% Complete**
- ⏳ **Phase 4:** API Endpoints (0/8 steps) - **0% Complete**
- ⏳ **Phase 5:** Polish & Deploy (0/5 steps) - **0% Complete**
- 💡 **Phase 6:** Golf Course Integration (0/7 steps) - **Future Enhancement**

**Total Project Progress: 20/40 steps (50% complete)**

---

### Phase 1: Foundation ✅ COMPLETE
- [x] Rails 8.1.1 API setup with PostgreSQL
- [x] RSpec testing framework configured
- [x] Core gems installed (JWT, Pundit, CORS, Propshaft)
- [x] Admin panel (Avo) installed and configured
- [x] Database configuration complete
- [x] Deployed to Render successfully

### Phase 2: Core Models with TDD 🚧 IN PROGRESS (73% complete - 11/15 steps)

**Authentication Setup (8/8 steps complete) ✅**

| Step | Task | Status |
|------|------|--------|
| 1 | Generate Rails 8 authentication scaffolding | ✅ Complete |
| 2 | Customize User model for API (name, provider, uid, avatar_url) | ✅ Complete |
| 3 | Write User model specs (29 passing tests) | ✅ Complete |
| 4 | Add JWT token generation and validation (11 passing tests) | ✅ Complete |
| 5 | Write request specs for authentication endpoints (28 passing tests) | ✅ Complete |
| 6 | Create API authentication controller (signup, login, Google) | ✅ Complete |
| 7 | Add Google OAuth token verification service (8 passing tests) | ✅ Complete |
| 8 | Create Google sign-in endpoint with specs | ✅ Complete |

**Core Models (4/4 steps complete) ✅**

| Step | Task | Status |
|------|------|--------|
| 9 | Generate Group model with TDD (13 passing specs) | ✅ Complete |
| 10 | Generate GroupMembership model with TDD (12 passing specs) | ✅ Complete |
| 11 | Generate TeeTimePosting model with TDD (25 passing specs) | ✅ Complete |
| 12 | Generate Reservation model with TDD (17 passing specs) | ✅ Complete |

**Admin & Documentation (3/3 steps complete) ✅**

| Step | Task | Status |
|------|------|--------|
| 13 | Create Avo resources for all models | ✅ Complete |
| 14 | Add password protection to Avo admin (HTTP Basic Auth) | ✅ Complete |
| 15 | Update documentation after each step | ✅ Ongoing |

**Notes:**
- All Avo resources have been created with comprehensive field definitions and associations
- Avo admin is protected with HTTP Basic Authentication (Step 14 complete)
- Documentation is updated after each major milestone

### Phase 3: Authorization ⏳ PLANNED

| Step | Task | Status |
|------|------|--------|
| 16 | Create Pundit policies for User resource | ⏳ Pending |
| 17 | Create Pundit policies for Group resource | ⏳ Pending |
| 18 | Create Pundit policies for TeeTimePosting resource | ⏳ Pending |
| 19 | Write authorization specs for all policies | ⏳ Pending |
| 20 | Integrate Pundit with API controllers | ⏳ Pending |

### Phase 4: API Endpoints ⏳ PLANNED

| Step | Task | Status |
|------|------|--------|
| 21 | Create API namespace and base controller | ⏳ Pending |
| 22 | Implement Auth endpoints (signup, login, Google OAuth) | ⏳ Pending |
| 23 | Implement Groups CRUD endpoints | ⏳ Pending |
| 24 | Implement TeeTimePostings CRUD endpoints | ⏳ Pending |
| 25 | Implement Reservations CRUD endpoints | ⏳ Pending |
| 26 | Add JSON serializers for all models | ⏳ Pending |
| 27 | Add error handling and validation responses | ⏳ Pending |
| 28 | Write comprehensive API documentation | ⏳ Pending |

### Phase 5: Polish & Deploy ⏳ PLANNED

| Step | Task | Status |
|------|------|--------|
| 29 | Add password protection to Avo admin | ⏳ Pending |
| 30 | Configure CORS for iOS app | ⏳ Pending |
| 31 | Set up seed data for development | ⏳ Pending |
| 32 | Final production deployment and testing | ⏳ Pending |
| 33 | iOS app integration testing | ⏳ Pending |

### Phase 6: Golf Course Integration ⏳ FUTURE

**Goal:** Integrate golf course data to provide course information with tee time postings

| Step | Task | Status |
|------|------|--------|
| 34 | Research and select golf course API provider | ⏳ Future |
| 35 | Generate GolfCourse model with TDD | ⏳ Future |
| 36 | Integrate golf course API service | ⏳ Future |
| 37 | Add golf course association to TeeTimePosting | ⏳ Future |
| 38 | Create API endpoints for golf course search/details | ⏳ Future |
| 39 | Add course stats display (par, slope, rating, holes) | ⏳ Future |
| 40 | Create Avo resource for golf course management | ⏳ Future |

**Golf Course Features:**
- Course name, location, and contact info
- Course stats (par, slope, rating, yardage)
- Number of holes (9 or 18)
- Amenities and facilities
- Course photos and description
- Associated with tee time postings

**API Options to Consider:**
- Golf Genius - Comprehensive course data and tee sheet management
- USGA Course Rating Database - Official ratings and slope
- GolfNow API - Course info with tee time availability
- Custom data entry - Manual course creation through admin panel

---

**Overall Progress: Phase 2 of 5 (93% of Phase 2 complete)**

## API Endpoints

### Authentication

#### POST /api/auth/signup
**Status:** ✅ Complete with 9 passing specs

Creates a new user account and returns a JWT token.

**Request:**
```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "name": "John Doe"
  }
}
```

**Successful Response (201 Created):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "avatar_url": null,
    "provider": null
  }
}
```

**Error Response (422 Unprocessable Entity):**
```json
{
  "errors": {
    "email_address": ["has already been taken"],
    "password": ["is too short (minimum is 8 characters)"]
  }
}
```

#### POST /api/auth/login
**Status:** ✅ Complete with 9 passing specs

Authenticates a user and returns a JWT token.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Successful Response (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "avatar_url": null,
    "provider": null
  }
}
```

**Error Response (401 Unauthorized):**
```json
{
  "error": "Invalid email or password"
}
```

**Features:**
- Case-insensitive email lookup
- Password validation using bcrypt
- Returns JWT token valid for 24 hours
- Token contains user_id and email in payload

#### POST /api/auth/google
**Status:** ✅ Complete with 10 passing specs

Authenticates a user via Google Sign-In token and returns a JWT token.

**Request:**
```json
{
  "token": "google_id_token_from_ios_app"
}
```

**Successful Response (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@gmail.com",
    "name": "John Doe",
    "avatar_url": "https://lh3.googleusercontent.com/...",
    "provider": "google"
  }
}
```

**Error Response (401 Unauthorized):**
```json
{
  "error": "Invalid Google token"
}
```

**Features:**
- Server-side Google ID token verification
- Requires verified email from Google
- Creates new user or updates existing OAuth user
- No password required for OAuth users
- Returns JWT token valid for 24 hours
- Sets provider to 'google' and stores Google uid

**Configuration:**
- Set `GOOGLE_CLIENT_ID` environment variable for production
- iOS app should use Google Sign-In SDK to obtain ID token
- Send the ID token to this endpoint for verification

## Models

### User
**Status:** ✅ Complete with 32 passing specs

The User model supports both email/password and OAuth authentication.

**Attributes:**
- `email_address` (string, required, unique) - User's email
- `password_digest` (string, optional) - Encrypted password (only for email/password users)
- `name` (string, required) - User's display name
- `provider` (string, optional) - OAuth provider (e.g., "google")
- `uid` (string, optional) - OAuth provider's user ID
- `avatar_url` (string, optional) - URL to user's avatar image
- `admin` (boolean, default: false) - Admin flag for Avo dashboard access
- `created_at`, `updated_at` (datetime) - Timestamps

**Associations:**
- `has_many :sessions` - User login sessions
- `has_many :group_memberships` - Groups the user is a member of
- `has_many :groups, through: :group_memberships` - Groups via memberships
- `has_many :tee_time_postings` - Tee time postings created by the user
- `has_many :reservations` - Reservations made by the user

**Key Methods:**
- `oauth_user?` - Returns true if user signed in via OAuth
- `User.from_oauth(...)` - Find or create user from OAuth data
- `generate_jwt` - Generates a JWT token for API authentication

**Validations:**
- Email format and uniqueness
- Password required (8+ chars) for non-OAuth users
- Provider/uid required together for OAuth users

### JWT Authentication
**Status:** ✅ Complete with 11 passing specs

The JsonWebToken service handles JWT encoding and decoding for API authentication.

**Service:** `JsonWebToken` (located at `app/services/json_web_token.rb`)

**Methods:**
- `JsonWebToken.encode(payload, exp: nil)` - Encodes a payload into a JWT token
  - `payload` (Hash): Data to encode in the token
  - `exp` (Integer, optional): Expiration time (defaults to 24 hours from now)
  - Returns: JWT token string
- `JsonWebToken.decode(token)` - Decodes a JWT token
  - `token` (String): JWT token to decode
  - Returns: Hash with decoded payload or nil if invalid/expired

**Features:**
- HS256 algorithm using Rails secret_key_base
- 24-hour token expiration by default
- Graceful handling of expired and invalid tokens
- Returns nil for any decode errors (expired, malformed, wrong signature)

### Google OAuth Verification
**Status:** ✅ Complete with 8 passing specs

The GoogleTokenVerifier service handles server-side verification of Google Sign-In ID tokens.

**Service:** `GoogleTokenVerifier` (located at `app/services/google_token_verifier.rb`)

**Methods:**
- `GoogleTokenVerifier.verify(token)` - Verifies a Google ID token
  - `token` (String): Google ID token from iOS app
  - Returns: Hash with token payload or nil if invalid/unverified
  - Validates token signature, expiration, and email verification status
- `GoogleTokenVerifier.extract_user_info(payload)` - Extracts user info from verified payload
  - `payload` (Hash): Verified Google token payload
  - Returns: Hash with uid, email, name, avatar_url, and provider

**Features:**
- Uses google-id-token gem for verification
- Validates email is verified by Google
- Requires GOOGLE_CLIENT_ID environment variable
- Graceful error handling returns nil for any verification failures
- Extracts user profile data (email, name, picture) from token

### Group
**Status:** ✅ Complete with 8 passing specs

The Group model represents a collection of golfers who share tee time postings.

**Attributes:**
- `name` (string, required) - Group name
- `description` (text, optional) - Group description
- `owner_id` (bigint, required) - User who created the group
- `created_at`, `updated_at` (datetime) - Timestamps

**Associations:**
- `belongs_to :owner` (User) - Group creator
- `has_many :group_memberships` - Join table records
- `has_many :members` through :group_memberships - Group members

**Validations:**
- Name presence and uniqueness scoped to owner
- Owner presence
- Allows same group name for different owners

**Database Indexes:**
- Composite unique index on `[owner_id, name]`
- Foreign key constraint to users table

### GroupMembership
**Status:** ✅ Complete with 12 passing specs

The GroupMembership model is a join table connecting Users to Groups as members.

**Attributes:**
- `user_id` (bigint, required) - Member user
- `group_id` (bigint, required) - Group being joined
- `created_at`, `updated_at` (datetime) - Timestamps

**Associations:**
- `belongs_to :user` - The member
- `belongs_to :group` - The group being joined

**Validations:**
- User presence
- Group presence
- User uniqueness scoped to group (can't join same group twice)

**Database Indexes:**
- Composite unique index on `[user_id, group_id]`
- Foreign key constraints to users and groups tables

**Cascading Deletes:**
- Destroyed when user is destroyed
- Destroyed when group is destroyed

### TeeTimePosting
**Status:** ✅ Complete with 25 passing specs

The TeeTimePosting model represents an available tee time spot that users can share with their groups or the public.

**Attributes:**
- `user_id` (bigint, required) - User who created the posting
- `group_id` (bigint, optional) - Group to share with (nil for public postings)
- `tee_time` (datetime, required) - Date and time of the tee time
- `course_name` (string, required) - Name of the golf course
- `available_spots` (integer, required) - Number of spots available
- `total_spots` (integer, optional) - Total number of spots in the tee time
- `notes` (text, optional) - Additional information or requirements
- `created_at`, `updated_at` (datetime) - Timestamps

**Associations:**
- `belongs_to :user` - Creator of the posting
- `belongs_to :group` (optional) - Group the posting is shared with
- `has_many :reservations` - Reservations made for this posting

**Validations:**
- User, tee_time, course_name, available_spots presence
- Available_spots must be greater than 0
- Total_spots must be greater than 0 (if provided)
- Tee time must be in the future (only on create)
- Available_spots must not exceed total_spots

**Scopes:**
- `upcoming` - Returns postings with future tee times
- `public_postings` - Returns postings without a group (group_id is nil)
- `for_group(group)` - Returns postings for a specific group

**Instance Methods:**
- `public?` - Returns true if posting has no group (public posting)
- `past?` - Returns true if tee time is in the past

**Database Indexes:**
- Index on `tee_time` for time-based queries
- Composite index on `[user_id, tee_time]` for user's postings
- Composite index on `[group_id, tee_time]` for group's postings
- Foreign key constraints to users and groups tables

**Business Logic:**
- Public postings (group_id = nil) are visible to all users
- Group postings are only visible to group members
- Past tee times can be updated without validation errors
- Postings are destroyed when user is destroyed
- Postings are destroyed when group is destroyed

### Reservation
**Status:** ✅ Complete with 17 passing specs

The Reservation model allows users to reserve available spots on tee time postings.

**Attributes:**
- `user_id` (bigint, required) - User making the reservation
- `tee_time_posting_id` (bigint, required) - The tee time posting being reserved
- `spots_reserved` (integer, required) - Number of spots being reserved
- `created_at`, `updated_at` (datetime) - Timestamps

**Associations:**
- `belongs_to :user` - User making the reservation
- `belongs_to :tee_time_posting` - The tee time posting being reserved

**Validations:**
- User, tee_time_posting, and spots_reserved presence
- Spots_reserved must be greater than 0
- User uniqueness scoped to tee_time_posting (can't reserve the same posting twice)
- Spots_reserved cannot exceed available_spots on the tee time posting

**Database Indexes:**
- Composite unique index on `[user_id, tee_time_posting_id]`
- Foreign key constraints to users and tee_time_postings tables

**Cascading Deletes:**
- Destroyed when user is destroyed
- Destroyed when tee_time_posting is destroyed

**Business Logic:**
- Users can only make one reservation per tee time posting
- Cannot reserve more spots than are available
- Different users can reserve spots on the same posting
- Same user can reserve spots on different postings

## Avo Admin Resources

All models have comprehensive Avo admin resources for data management. The admin dashboard is available at `/avo` and protected with HTTP Basic Authentication.

### User Resource
**Features:**
- Search by email or name
- Display fields: ID, name, email, provider (badge), avatar
- Password management for new/edit forms
- Associated records: sessions, group memberships, groups, tee time postings, reservations
- OAuth users show "Google" badge, password users show "Password" badge

### Group Resource
**Features:**
- Search by name
- Display fields: ID, name, description, owner
- Associated records: group memberships, members (through memberships), tee time postings
- Shows owner information with searchable lookup

### GroupMembership Resource
**Features:**
- Display fields: ID, user, group, joined at (created_at)
- Searchable user and group associations
- Join table visualization for user-group relationships

### TeeTimePosting Resource
**Features:**
- Search by course name or notes
- Display fields: ID, user, group, tee time, course name, spots (available/total), notes
- Associated records: reservations
- Validation hints: minimum 1 spot for available and total spots
- Optional group field for public vs. group postings

### Reservation Resource
**Features:**
- Display fields: ID, user, tee time posting, spots reserved, reserved at (created_at)
- Searchable user and tee time posting associations
- Validation hints: minimum 1 spot, help text for spots reserved
- Shows when reservation was made

## Development Approach

This project follows **Test-Driven Development (TDD)** practices:
1. Write failing tests first (Red)
2. Implement minimal code to pass (Green)
3. Refactor for quality (Refactor)

## Contributing

This is a private project for the Golf Dads community.

## License

All rights reserved.
