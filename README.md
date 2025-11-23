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
- **Devise** - User authentication
- **Devise-JWT** - JWT token-based authentication for API
- **Pundit** - Authorization policies

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

### Phase 1: Foundation ✅
- [x] Rails 8.1.1 API setup with PostgreSQL
- [x] RSpec testing framework configured
- [x] Core gems installed (Devise, JWT, Pundit, CORS)
- [x] Admin panel (Avo) installed
- [x] Database configuration complete

### Phase 2: Core Models (Coming Next)
- [ ] User model with authentication
- [ ] Group model for golf groups
- [ ] GroupMembership for user-group associations
- [ ] TeeTimePosting for available tee times
- [ ] Reservation for claiming spots
- [ ] Course model (optional)

### Phase 3: Authentication & Authorization (Planned)
- [ ] JWT authentication endpoints
- [ ] User registration/login/logout
- [ ] Pundit policies

### Phase 4: API Endpoints (Planned)
- [ ] Auth endpoints
- [ ] Groups CRUD
- [ ] Tee time postings
- [ ] Reservations

## Development Approach

This project follows **Test-Driven Development (TDD)** practices:
1. Write failing tests first (Red)
2. Implement minimal code to pass (Green)
3. Refactor for quality (Refactor)

## Contributing

This is a private project for the Golf Dads community.

## License

All rights reserved.
