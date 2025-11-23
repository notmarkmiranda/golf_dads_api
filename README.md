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
- **Pundit** (installed) - Authorization policies
- **Google OAuth** (planned) - OAuth2 authentication via Google Sign-In

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

Once configured, Avo admin dashboard will be available at:
```
http://localhost:3000/avo
```

## Execution Plan

This project is being built in **5 phases** with **33 total steps** using Test-Driven Development (TDD).

**Progress Overview:**
- ✅ **Phase 1:** Foundation (6/6 steps) - **100% Complete**
- 🚧 **Phase 2:** Core Models with TDD (5/15 steps) - **33% Complete** ← Current Phase
- ⏳ **Phase 3:** Authorization (0/5 steps) - **0% Complete**
- ⏳ **Phase 4:** API Endpoints (0/8 steps) - **0% Complete**
- ⏳ **Phase 5:** Polish & Deploy (0/5 steps) - **0% Complete**

**Total Project Progress: 11/33 steps (33% complete)**

---

### Phase 1: Foundation ✅ COMPLETE
- [x] Rails 8.1.1 API setup with PostgreSQL
- [x] RSpec testing framework configured
- [x] Core gems installed (JWT, Pundit, CORS, Propshaft)
- [x] Admin panel (Avo) installed and configured
- [x] Database configuration complete
- [x] Deployed to Render successfully

### Phase 2: Core Models with TDD 🚧 IN PROGRESS (33% complete - 5/15 steps)

**Authentication Setup (5/8 steps complete)**

| Step | Task | Status |
|------|------|--------|
| 1 | Generate Rails 8 authentication scaffolding | ✅ Complete |
| 2 | Customize User model for API (name, provider, uid, avatar_url) | ✅ Complete |
| 3 | Write User model specs (29 passing tests) | ✅ Complete |
| 4 | Add JWT token generation and validation (11 passing tests) | ✅ Complete |
| 5 | Create API authentication controller (signup, login) | 🔄 Next |
| 6 | Write request specs for authentication endpoints | ⏳ Pending |
| 7 | Add Google OAuth token verification | ⏳ Pending |
| 8 | Create Google sign-in endpoint with specs | ⏳ Pending |

**Core Models (0/4 steps complete)**

| Step | Task | Status |
|------|------|--------|
| 9 | Generate Group model with TDD | ⏳ Pending |
| 10 | Generate GroupMembership model with TDD | ⏳ Pending |
| 11 | Generate TeeTimePosting model with TDD | ⏳ Pending |
| 12 | Generate Reservation model with TDD | ⏳ Pending |

**Admin & Documentation (3/3 steps complete)**

| Step | Task | Status |
|------|------|--------|
| 13 | Create Avo resource for User | ✅ Complete |
| 14 | Add password protection to Avo admin | ⏳ Pending |
| 15 | Update documentation after each step | ✅ Ongoing |

**Notes:**
- All User Avo resources will be created alongside their models
- Documentation is updated after each major milestone
- Password protection for Avo will be added after core models are complete

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

---

**Overall Progress: Phase 2 of 5 (33% of Phase 2 complete)**

## Models

### User
**Status:** ✅ Complete with 29 passing specs

The User model supports both email/password and OAuth authentication.

**Attributes:**
- `email_address` (string, required, unique) - User's email
- `password_digest` (string, optional) - Encrypted password (only for email/password users)
- `name` (string, required) - User's display name
- `provider` (string, optional) - OAuth provider (e.g., "google")
- `uid` (string, optional) - OAuth provider's user ID
- `avatar_url` (string, optional) - URL to user's avatar image
- `created_at`, `updated_at` (datetime) - Timestamps

**Associations:**
- `has_many :sessions` - User login sessions

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

## Development Approach

This project follows **Test-Driven Development (TDD)** practices:
1. Write failing tests first (Red)
2. Implement minimal code to pass (Green)
3. Refactor for quality (Refactor)

## Contributing

This is a private project for the Golf Dads community.

## License

All rights reserved.
