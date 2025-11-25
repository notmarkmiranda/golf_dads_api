# Golf Dads iOS App - Execution Plan

## Project Overview

A native iOS application built with SwiftUI that consumes the Golf Dads API. Users can browse tee times, create postings, join groups, and manage reservations.

## Tech Stack

### Core Framework
- **SwiftUI** - Modern declarative UI framework
- **iOS 17+** - Target minimum version
- **Swift 6** - Latest Swift language features
- **Xcode 16+** - Development environment

### Architecture
- **MVVM (Model-View-ViewModel)** - Clean separation of concerns
- **Async/Await** - Modern concurrency for API calls
- **Combine** - Reactive state management where needed
- **Swift Concurrency** - Structured concurrency patterns

### Networking & Authentication
- **URLSession** with async/await - Native HTTP client
- **Keychain** - Secure JWT token storage
- **Google Sign-In SDK** - OAuth authentication
- **Codable** - JSON parsing

### Testing
- **XCTest** - Unit testing framework
- **ViewInspector** - SwiftUI view testing
- **@testable import** - Internal access for testing
- **Mock protocols** - Dependency injection for testability
- **Preview mocks** - SwiftUI preview data

### Code Quality
- **SwiftLint** - Code style enforcement
- **Swift Testing** (iOS 18+) - Modern testing framework (optional upgrade)
- **TDD approach** - Write tests before implementation

---

## Execution Plan

This project will be built in **6 phases** with **45 total steps** using Test-Driven Development (TDD).

**🔔 Important: Documentation Updates**
- This execution plan should be updated **after completing each step**
- Update progress percentages, test counts, and deliverables sections
- Commit documentation changes along with code changes
- Keep the Progress Overview section current at all times

**Progress Overview:**
- ✅ **Phase 1:** Project Setup & Configuration (6/6 steps) - **100% Complete**
- 🚧 **Phase 2:** Core Services & Authentication (3/10 steps) - **30% Complete** ← Current Phase
- 💡 **Phase 3:** Models & API Client (0/8 steps)
- 💡 **Phase 4:** Authentication Flows (0/8 steps)
- 💡 **Phase 5:** Main Features (0/10 steps)
- 💡 **Phase 6:** Polish & App Store (0/3 steps)

**Total Project Progress: 9/45 steps (20% complete)**

---

### Phase 1: Project Setup & Configuration ✅ COMPLETE (6/6 steps)

| Step | Task | Status | Tests |
|------|------|--------|-------|
| 1 | Create new Xcode project (iOS App, SwiftUI, Swift) | ✅ Complete | N/A |
| 2 | Configure git repository with comprehensive .gitignore | ✅ Complete | N/A |
| 3 | Add SwiftLint configuration with comprehensive rules | ✅ Complete | N/A |
| 4 | Set up folder structure (Models, Views, ViewModels, Services, Utils, Tests) | ✅ Complete | N/A |
| 5 | Document Swift Package dependencies (ready to install in Xcode) | ✅ Complete | N/A |
| 6 | Create environment configuration files (.xcconfig examples) | ✅ Complete | N/A |

**Deliverables:** ✅ All Complete
- ✅ Xcode project created at `/Users/weatherby/Development/golf_dads/GolfDads`
- ✅ Git repository initialized with proper .gitignore
- ✅ SwiftLint configuration ready (.swiftlint.yml)
- ✅ MVVM folder structure created and documented (FOLDER_STRUCTURE.md)
- ✅ Dependencies documented (DEPENDENCIES.md) - ready to install via SPM
- ✅ Environment configs created (Development.xcconfig.example, Production.xcconfig.example)
- ✅ Comprehensive setup documentation in Config/README.md

**Notes:**
- Next manual step: Install Swift Package dependencies in Xcode (see DEPENDENCIES.md)
- SwiftLint integration into build phases will be done when first running project
- Configuration values (.xcconfig) need to be filled in before Phase 2

---

### Phase 2: Core Services & Authentication 🚧 (3/10 steps - 30% complete)

| Step | Task | Status | Tests |
|------|------|--------|-------|
| 7 | Create `APIConfiguration` with base URL and environment handling | ✅ Complete | 7 tests passing |
| 8 | Create `KeychainService` protocol and implementation for token storage | ✅ Complete | 16 tests passing |
| 9 | Create `APIError` enum with proper error handling | ✅ Complete | Integrated |
| 10 | Create `NetworkService` protocol for HTTP requests | ⏳ Pending | Unit tests |
| 11 | Implement `NetworkService` with URLSession, JWT token injection, error handling | ⏳ Pending | Unit tests |
| 12 | Create mock `NetworkService` for testing | ⏳ Pending | Unit tests |
| 13 | Create `AuthenticationService` protocol for auth operations | ⏳ Pending | Unit tests |
| 14 | Implement `AuthenticationService` (signup, login, Google OAuth, token refresh) | ⏳ Pending | Unit tests |
| 15 | Create `AuthenticationManager` to manage auth state (published properties) | ⏳ Pending | Unit tests |
| 16 | Write integration tests for auth flow | ⏳ Pending | Integration tests |

**Completed Deliverables:**

✅ **APIConfiguration.swift** (Step 7)
- Environment detection (Development/Production)
- Base URL configuration with simulator/device detection
- Comprehensive endpoint enum for all API routes
- Google Client ID configuration support
- 7 passing tests

✅ **KeychainService.swift** (Step 8)
- Protocol-based design (`KeychainServiceProtocol`)
- Secure JWT token storage using KeychainAccess library
- Support for access and refresh tokens
- `MockKeychainService` for testing
- Security: `whenUnlockedThisDeviceOnly`, no iCloud sync
- 16 passing tests

✅ **APIError.swift** (Step 9)
- Comprehensive error types (network, HTTP, data, auth, config)
- User-friendly error messages
- Factory methods for URLError and HTTP responses
- Retry and re-authentication detection
- Validation error formatting

**Total Tests Passing: 23/23** (7 APIConfiguration + 16 KeychainService)

**Testing Strategy:**
- **Unit tests** for each service with mocked dependencies
- **Protocol-based design** for easy mocking
- **Test token storage** with mock keychain
- **Test error scenarios** (network failures, invalid tokens, etc.)

**Key Files:**
- ✅ `Services/APIConfiguration.swift` + tests
- ✅ `Services/KeychainService.swift` + tests
- ✅ `Utils/APIError.swift`
- ⏳ `Services/NetworkService.swift` (next)
- ⏳ `Services/AuthenticationService.swift`
- ⏳ `Managers/AuthenticationManager.swift`

---

### Phase 3: Models & API Client 🚧 (0/8 steps)

| Step | Task | Status | Tests |
|------|------|--------|-------|
| 17 | Create `User` model with Codable conformance | ⏳ Pending | Unit tests |
| 18 | Create `Group` model with Codable conformance | ⏳ Pending | Unit tests |
| 19 | Create `TeeTimePosting` model with Codable conformance and date formatting | ⏳ Pending | Unit tests |
| 20 | Create `Reservation` model with Codable conformance | ⏳ Pending | Unit tests |
| 21 | Create API request/response DTOs (Data Transfer Objects) | ⏳ Pending | Unit tests |
| 22 | Create `APIClient` with methods for all endpoints | ⏳ Pending | Unit tests |
| 23 | Add proper date formatting (ISO8601) and JSON decoding strategies | ⏳ Pending | Unit tests |
| 24 | Create mock data for SwiftUI previews and tests | ⏳ Pending | Preview data |

**Testing Strategy:**
- **Codable tests** with sample JSON from API
- **Date parsing tests** for various timezone scenarios
- **Validation tests** for model constraints
- **Mock data** that matches API responses exactly

**Key Files:**
- `Models/User.swift`
- `Models/Group.swift`
- `Models/TeeTimePosting.swift`
- `Models/Reservation.swift`
- `Services/APIClient.swift`
- `Tests/Models/` - Model tests
- `PreviewContent/MockData.swift`

---

### Phase 4: Authentication Flows 🚧 (0/8 steps)

| Step | Task | Status | Tests |
|------|------|--------|-------|
| 25 | Create `WelcomeView` (app entry with login/signup/Google options) | ⏳ Pending | View tests |
| 26 | Create `WelcomeViewModel` with authentication actions | ⏳ Pending | Unit tests |
| 27 | Create `SignUpView` with form validation | ⏳ Pending | View tests |
| 28 | Create `SignUpViewModel` with validation logic and API integration | ⏳ Pending | Unit tests |
| 29 | Create `LoginView` with form validation | ⏳ Pending | View tests |
| 30 | Create `LoginViewModel` with validation logic and API integration | ⏳ Pending | Unit tests |
| 31 | Integrate Google Sign-In button and flow | ⏳ Pending | Integration tests |
| 32 | Create `RootView` with auth state handling (logged in vs logged out) | ⏳ Pending | View tests |

**Testing Strategy:**
- **View tests** using ViewInspector to verify UI elements
- **ViewModel tests** with mock services
- **Validation tests** for email format, password requirements
- **Navigation tests** for proper flow between screens
- **Google Sign-In** mocked for testing

**Key Files:**
- `Views/Authentication/WelcomeView.swift`
- `Views/Authentication/SignUpView.swift`
- `Views/Authentication/LoginView.swift`
- `Views/RootView.swift`
- `ViewModels/Authentication/` - All auth ViewModels
- `Tests/ViewModels/Authentication/` - ViewModel tests
- `Tests/Views/Authentication/` - View tests

---

### Phase 5: Main Features 🚧 (0/10 steps)

**5A: Navigation & Home (3 steps)**

| Step | Task | Status | Tests |
|------|------|--------|-------|
| 33 | Create `MainTabView` with tabs (Browse, Groups, Profile) | ⏳ Pending | View tests |
| 34 | Create `BrowseView` displaying public tee time postings | ⏳ Pending | View/VM tests |
| 35 | Create `BrowseViewModel` with filtering and loading states | ⏳ Pending | Unit tests |

**5B: Tee Time Features (3 steps)**

| Step | Task | Status | Tests |
|------|------|--------|-------|
| 36 | Create `TeeTimeDetailView` showing posting details + reserve action | ⏳ Pending | View/VM tests |
| 37 | Create `CreateTeeTimeView` with form for new postings | ⏳ Pending | View/VM tests |
| 38 | Create `MyPostingsView` showing user's created postings + edit/delete | ⏳ Pending | View/VM tests |

**5C: Groups Features (2 steps)**

| Step | Task | Status | Tests |
|------|------|--------|-------|
| 39 | Create `GroupsView` listing user's groups + create/join actions | ⏳ Pending | View/VM tests |
| 40 | Create `GroupDetailView` showing members + group postings | ⏳ Pending | View/VM tests |

**5D: Profile & Settings (2 steps)**

| Step | Task | Status | Tests |
|------|------|--------|-------|
| 41 | Create `ProfileView` with user info and logout | ⏳ Pending | View/VM tests |
| 42 | Create `MyReservationsView` showing user's reservations + cancel action | ⏳ Pending | View/VM tests |

**Testing Strategy:**
- **View tests** for all UI components
- **ViewModel tests** with mocked API client
- **List tests** for empty states, loading states, error states
- **Form validation tests** for create/edit flows
- **Navigation tests** for proper routing
- **State management tests** for data updates

**Key Files:**
- `Views/MainTabView.swift`
- `Views/Browse/` - Browse feature views
- `Views/TeeTimes/` - Tee time management views
- `Views/Groups/` - Group feature views
- `Views/Profile/` - Profile feature views
- `ViewModels/` - All feature ViewModels
- `Tests/` - Comprehensive test coverage

---

### Phase 6: Polish & App Store 🚧 (0/3 steps)

| Step | Task | Status | Tests |
|------|------|--------|-------|
| 43 | Add app icon, launch screen, and branding | ⏳ Pending | N/A |
| 44 | Add error handling UI (alerts, retry, offline mode) | ⏳ Pending | View tests |
| 45 | Prepare App Store metadata (screenshots, description, privacy policy) | ⏳ Pending | N/A |

**Additional Polish:**
- Accessibility labels for VoiceOver
- Dark mode support
- Haptic feedback for key actions
- Pull-to-refresh on lists
- Skeleton loading states
- Smooth animations and transitions

---

## Testing Best Practices

### Unit Testing with XCTest

**Service Tests Example:**
```swift
import XCTest
@testable import GolfDads

final class NetworkServiceTests: XCTestCase {
    var sut: NetworkService!
    var mockURLSession: MockURLSession!
    var mockKeychainService: MockKeychainService!

    override func setUp() {
        super.setUp()
        mockURLSession = MockURLSession()
        mockKeychainService = MockKeychainService()
        sut = NetworkService(
            session: mockURLSession,
            keychainService: mockKeychainService
        )
    }

    func testRequestWithValidToken() async throws {
        // Given
        mockKeychainService.token = "valid_jwt_token"
        let expectedData = """
        {"email_address": "test@example.com"}
        """.data(using: .utf8)!
        mockURLSession.mockData = expectedData

        // When
        let response: User = try await sut.request(.getCurrentUser)

        // Then
        XCTAssertEqual(response.emailAddress, "test@example.com")
        XCTAssertTrue(mockURLSession.lastRequest?.allHTTPHeaderFields?["Authorization"]?.contains("Bearer") ?? false)
    }
}
```

**ViewModel Tests Example:**
```swift
import XCTest
@testable import GolfDads

final class BrowseViewModelTests: XCTestCase {
    var sut: BrowseViewModel!
    var mockAPIClient: MockAPIClient!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        sut = BrowseViewModel(apiClient: mockAPIClient)
    }

    func testLoadPostingsSuccess() async throws {
        // Given
        let mockPostings = [TeeTimePosting.mock1, TeeTimePosting.mock2]
        mockAPIClient.mockPostings = mockPostings

        // When
        await sut.loadPostings()

        // Then
        XCTAssertEqual(sut.postings.count, 2)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testLoadPostingsFailure() async throws {
        // Given
        mockAPIClient.shouldFail = true

        // When
        await sut.loadPostings()

        // Then
        XCTAssertTrue(sut.postings.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
    }
}
```

### SwiftUI View Testing with ViewInspector

**View Tests Example:**
```swift
import XCTest
import ViewInspector
@testable import GolfDads

final class LoginViewTests: XCTestCase {
    func testLoginButtonDisabledWhenFieldsEmpty() throws {
        // Given
        let viewModel = LoginViewModel(authService: MockAuthenticationService())
        let view = LoginView(viewModel: viewModel)

        // When
        let button = try view.inspect().find(button: "Log In")

        // Then
        XCTAssertTrue(try button.isDisabled())
    }

    func testLoginButtonEnabledWhenFieldsFilled() throws {
        // Given
        let viewModel = LoginViewModel(authService: MockAuthenticationService())
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        let view = LoginView(viewModel: viewModel)

        // When
        let button = try view.inspect().find(button: "Log In")

        // Then
        XCTAssertFalse(try button.isDisabled())
    }
}
```

### Mock Objects Pattern

**Protocol-First Design:**
```swift
// Protocol for testability
protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}

// Real implementation
class NetworkService: NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        // Real network call
    }
}

// Mock for testing
class MockNetworkService: NetworkServiceProtocol {
    var mockResponse: Any?
    var shouldThrowError = false

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        if shouldThrowError {
            throw APIError.networkError
        }
        return mockResponse as! T
    }
}
```

---

## Code Organization

```
GolfDads/
├── GolfDads.xcodeproj
├── GolfDads/
│   ├── App/
│   │   ├── GolfDadsApp.swift          # App entry point
│   │   └── RootView.swift             # Root view with auth state
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Group.swift
│   │   ├── TeeTimePosting.swift
│   │   └── Reservation.swift
│   ├── Views/
│   │   ├── Authentication/
│   │   │   ├── WelcomeView.swift
│   │   │   ├── SignUpView.swift
│   │   │   └── LoginView.swift
│   │   ├── Browse/
│   │   │   └── BrowseView.swift
│   │   ├── TeeTimes/
│   │   │   ├── TeeTimeDetailView.swift
│   │   │   ├── CreateTeeTimeView.swift
│   │   │   └── MyPostingsView.swift
│   │   ├── Groups/
│   │   │   ├── GroupsView.swift
│   │   │   └── GroupDetailView.swift
│   │   ├── Profile/
│   │   │   ├── ProfileView.swift
│   │   │   └── MyReservationsView.swift
│   │   ├── Components/            # Reusable UI components
│   │   └── MainTabView.swift
│   ├── ViewModels/
│   │   ├── Authentication/
│   │   ├── Browse/
│   │   ├── TeeTimes/
│   │   ├── Groups/
│   │   └── Profile/
│   ├── Services/
│   │   ├── APIConfiguration.swift
│   │   ├── NetworkService.swift
│   │   ├── AuthenticationService.swift
│   │   ├── APIClient.swift
│   │   └── KeychainService.swift
│   ├── Managers/
│   │   └── AuthenticationManager.swift
│   ├── Utils/
│   │   ├── Extensions/
│   │   └── Helpers/
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   └── Info.plist
│   └── PreviewContent/
│       └── MockData.swift
├── GolfDadsTests/
│   ├── ModelTests/
│   ├── ServiceTests/
│   ├── ViewModelTests/
│   └── ViewTests/
├── GolfDadsUITests/              # Optional UI automation tests
└── .swiftlint.yml
```

---

## Key Dependencies

### Swift Package Manager (SPM)

**Required:**
1. **GoogleSignIn** - `https://github.com/google/GoogleSignIn-iOS`
   - OAuth authentication with Google

2. **KeychainAccess** - `https://github.com/kishikawakatsumi/KeychainAccess`
   - Secure token storage

3. **ViewInspector** - `https://github.com/nalexn/ViewInspector`
   - SwiftUI view testing

**Optional/Future:**
4. **swift-snapshot-testing** - `https://github.com/pointfreeco/swift-snapshot-testing`
   - UI snapshot testing for regression detection

---

## Environment Configuration

### Info.plist Keys

```xml
<key>API_BASE_URL</key>
<string>$(API_BASE_URL)</string>

<key>GOOGLE_CLIENT_ID</key>
<string>$(GOOGLE_CLIENT_ID)</string>

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

### Xcode Configuration Files

Create `.xcconfig` files for different environments:

**Development.xcconfig:**
```
API_BASE_URL = http:/​/localhost:3000/api
GOOGLE_CLIENT_ID = your-dev-client-id.apps.googleusercontent.com
```

**Production.xcconfig:**
```
API_BASE_URL = https:/​/your-production-api.com/api
GOOGLE_CLIENT_ID = your-prod-client-id.apps.googleusercontent.com
```

---

## Git Repository Structure

### Recommended .gitignore

```gitignore
# Xcode
*.xcodeproj/*
!*.xcodeproj/project.pbxproj
!*.xcodeproj/xcshareddata/
*.xcworkspace/*
!*.xcworkspace/contents.xcworkspacedata

# Swift Package Manager
.swiftpm/
.build/

# CocoaPods (if used)
Pods/

# Secrets
*.xcconfig
Config.plist

# Build artifacts
DerivedData/
build/

# User-specific
*.xcuserstate
*.xcuserdatad/

# macOS
.DS_Store
```

### Repository Setup

```bash
# In parent directory of golf_api
cd /Users/weatherby/Development/golf_dads
mkdir golf_ios
cd golf_ios
git init
# Create Xcode project here
git add .
git commit -m "Initial commit: Xcode project setup"
git remote add origin git@github.com:notmarkmiranda/golf_dads_ios.git
git push -u origin main
```

---

## Development Workflow

### TDD Cycle

1. **Write failing test** - Red
2. **Write minimal code to pass** - Green
3. **Refactor** - Clean
4. **Repeat**

### Running Tests

```bash
# Run all tests
cmd + U in Xcode

# Run specific test
cmd + click on test method

# Test coverage
Enable "Gather coverage for all targets" in scheme settings
```

### Continuous Integration (Future)

Use GitHub Actions or Xcode Cloud to:
- Run tests on every PR
- Enforce minimum test coverage (aim for 80%+)
- Run SwiftLint checks
- Build and archive for TestFlight

---

## Next Steps

1. **Create iOS repository** in sibling directory
2. **Set up Xcode project** following Phase 1 steps
3. **Start Phase 2** with TDD approach for core services
4. **Reference API documentation** from `golf_api/README.md`

**Note:** This plan assumes the API is complete and deployed. Any API changes should be documented and communicated before updating the iOS app.

---

## Success Criteria

- [ ] 80%+ test coverage across all modules
- [ ] All API endpoints integrated and tested
- [ ] Zero SwiftLint warnings
- [ ] App runs on iOS 17+ devices
- [ ] Smooth user experience with proper loading/error states
- [ ] Secure token storage and refresh
- [ ] Ready for TestFlight distribution

**Estimated Timeline:** 4-6 weeks for MVP (based on 2-3 hours/day development)
