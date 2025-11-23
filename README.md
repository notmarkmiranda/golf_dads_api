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
- **JWT** (planned) - Token-based authentication for API
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

## Project Status

### Phase 1: Foundation ✅ COMPLETE
- [x] Rails 8.1.1 API setup with PostgreSQL
- [x] RSpec testing framework configured
- [x] Core gems installed (JWT, Pundit, CORS, Propshaft)
- [x] Admin panel (Avo) installed and configured
- [x] Database configuration complete
- [x] Deployed to Render successfully

### Phase 2: Core Models with TDD 🚧 IN PROGRESS (21% complete)

**Authentication Setup (3/8 complete)**
- [x] Generate Rails 8 authentication scaffolding
- [x] Customize User model for API
  - Email/password authentication
  - OAuth fields (provider, uid, avatar_url)
  - Password optional for OAuth users
- [x] Write User model specs - **25 passing tests** ✅
- [x] Create Avo resource for User with admin interface
- [ ] Add JWT token generation and validation
- [ ] Create API authentication controller (signup, login)
- [ ] Write request specs for authentication endpoints
- [ ] Add Google OAuth token verification
- [ ] Create Google sign-in endpoint with specs

**Core Models (0/4 complete)**
- [ ] Group model with TDD
- [ ] GroupMembership model with TDD
- [ ] TeeTimePosting model with TDD
- [ ] Reservation model with TDD

**Admin & Documentation (1/3 complete)**
- [x] User Avo resource ✅
- [ ] Avo resources for other models
- [ ] Password protect Avo admin
- [ ] Documentation updates (ongoing)

### Phase 3: Authorization (PLANNED)
- [ ] Pundit policies for User, Group, TeeTimePosting
- [ ] Authorization specs

### Phase 4: API Endpoints (PLANNED)
- [ ] Auth endpoints (signup, login, Google OAuth)
- [ ] Groups CRUD
- [ ] Tee time postings CRUD
- [ ] Reservations CRUD

## Models

### User
**Status:** ✅ Complete with 25 passing specs

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

**Validations:**
- Email format and uniqueness
- Password required (8+ chars) for non-OAuth users
- Provider/uid required together for OAuth users

## Development Approach

This project follows **Test-Driven Development (TDD)** practices:
1. Write failing tests first (Red)
2. Implement minimal code to pass (Green)
3. Refactor for quality (Refactor)

## Contributing

This is a private project for the Golf Dads community.

## License

All rights reserved.
