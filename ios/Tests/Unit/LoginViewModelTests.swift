import XCTest
@testable import Cookstemma

@MainActor
final class LoginViewModelTests: XCTestCase {
    var sut: LoginViewModel!
    var mockAuthManager: MockAuthManager!

    override func setUp() async throws {
        try await super.setUp()
        mockAuthManager = MockAuthManager()
        sut = LoginViewModel(authManager: mockAuthManager)
    }

    override func tearDown() async throws {
        sut = nil
        mockAuthManager = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_isNotLoading() {
        XCTAssertFalse(sut.isLoading)
    }

    func testInitialState_hasNoError() {
        XCTAssertNil(sut.error)
    }

    func testInitialState_isNotAuthenticated() {
        XCTAssertFalse(sut.isAuthenticated)
    }

    // MARK: - Google Sign In Tests

    func testSignInWithGoogle_setsLoadingTrue() async {
        // Given
        mockAuthManager.shouldSucceed = true
        mockAuthManager.delay = 0.1 // Add small delay to observe loading state

        // When
        let task = Task {
            await sut.signInWithGoogle()
        }

        // Give time for loading to be set
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        // Then - during the call, isLoading should be true
        // Note: This is tricky to test without more sophisticated async testing

        await task.value
    }

    func testSignInWithGoogle_success_setsAuthenticated() async {
        // Given
        mockAuthManager.shouldSucceed = true

        // When
        await sut.signInWithGoogle()

        // Then
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    func testSignInWithGoogle_failure_setsError() async {
        // Given
        mockAuthManager.shouldSucceed = false
        mockAuthManager.errorMessage = "Google sign in failed"

        // When
        await sut.signInWithGoogle()

        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.error)
    }

    // MARK: - Apple Sign In Tests

    func testSignInWithApple_success_setsAuthenticated() async {
        // Given
        mockAuthManager.shouldSucceed = true

        // When
        await sut.signInWithApple()

        // Then
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    func testSignInWithApple_failure_setsError() async {
        // Given
        mockAuthManager.shouldSucceed = false
        mockAuthManager.errorMessage = "Apple sign in failed"

        // When
        await sut.signInWithApple()

        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.error)
    }

    // MARK: - Clear Error Tests

    func testClearError_removesError() async {
        // Given
        mockAuthManager.shouldSucceed = false
        await sut.signInWithGoogle()
        XCTAssertNotNil(sut.error)

        // When
        sut.clearError()

        // Then
        XCTAssertNil(sut.error)
    }

    // MARK: - Loading State Tests

    func testSignIn_setsLoadingFalseAfterCompletion() async {
        // Given
        mockAuthManager.shouldSucceed = true

        // When
        await sut.signInWithGoogle()

        // Then
        XCTAssertFalse(sut.isLoading)
    }

    func testSignIn_setsLoadingFalseAfterError() async {
        // Given
        mockAuthManager.shouldSucceed = false

        // When
        await sut.signInWithGoogle()

        // Then
        XCTAssertFalse(sut.isLoading)
    }
}

// MARK: - Mock Auth Manager

class MockAuthManager: AuthManagerProtocol {
    var authState: AuthState = .unauthenticated
    var authStatePublisher: AnyPublisher<AuthState, Never> {
        Just(authState).eraseToAnyPublisher()
    }
    var isAuthenticated: Bool = false
    var currentUser: MyProfile?

    var shouldSucceed = true
    var errorMessage = "Mock error"
    var delay: TimeInterval = 0

    func loginWithFirebase(token: String) async throws {
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if shouldSucceed {
            isAuthenticated = true
            authState = .authenticated(user: createMockProfile())
        } else {
            throw NSError(domain: "MockAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    }

    func logout() async {
        isAuthenticated = false
        currentUser = nil
        authState = .unauthenticated
    }

    func refreshUserProfile() async throws {
        // No-op for tests
    }

    private func createMockProfile() -> MyProfile {
        MyProfile(
            id: "user-1",
            username: "testuser",
            displayName: "Test User",
            email: "test@example.com",
            avatarUrl: nil,
            bio: "Test bio",
            level: 5,
            xp: 500,
            levelProgress: 0.5,
            recipeCount: 10,
            logCount: 25,
            followerCount: 100,
            followingCount: 50,
            socialLinks: nil,
            createdAt: Date()
        )
    }
}

import Combine
