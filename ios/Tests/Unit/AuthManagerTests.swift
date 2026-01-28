import XCTest
import Combine
@testable import Cookstemma

@MainActor
final class AuthManagerTests: XCTestCase {
    var sut: AuthManager!
    var mockAPIClient: MockAPIClient!
    var mockTokenManager: MockTokenManager!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        mockAPIClient = MockAPIClient()
        mockTokenManager = MockTokenManager()
        sut = AuthManager(apiClient: mockAPIClient, tokenManager: mockTokenManager)
        cancellables = []
    }

    override func tearDown() async throws {
        sut = nil
        mockAPIClient = nil
        mockTokenManager = nil
        cancellables = nil
        try await super.tearDown()
    }

    // MARK: - Login Tests

    func testLoginWithFirebase_success_savesTokens() async throws {
        // Given
        let authResponse = AuthResponse(
            accessToken: "new-access-token",
            refreshToken: "new-refresh-token",
            expiresIn: 3600
        )
        mockAPIClient.mockResponse = authResponse

        let userProfile = createMockProfile()
        mockAPIClient.mockResponses = [authResponse, userProfile]

        // When
        try await sut.loginWithFirebase(token: "firebase-token")

        // Then
        XCTAssertEqual(mockTokenManager.mockAccessToken, "new-access-token")
        XCTAssertEqual(mockTokenManager.mockRefreshToken, "new-refresh-token")
    }

    func testLoginWithFirebase_success_fetchesUserProfile() async throws {
        // Given
        let authResponse = AuthResponse(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresIn: 3600
        )
        let userProfile = createMockProfile()
        mockAPIClient.mockResponses = [authResponse, userProfile]

        // When
        try await sut.loginWithFirebase(token: "firebase-token")

        // Then
        XCTAssertEqual(sut.currentUser?.username, "testuser")
    }

    func testLoginWithFirebase_success_setsAuthenticatedState() async throws {
        // Given
        let authResponse = AuthResponse(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresIn: 3600
        )
        let userProfile = createMockProfile()
        mockAPIClient.mockResponses = [authResponse, userProfile]

        // When
        try await sut.loginWithFirebase(token: "firebase-token")

        // Then
        XCTAssertTrue(sut.isAuthenticated)
        if case .authenticated(let user) = sut.authState {
            XCTAssertEqual(user.id, "user-1")
        } else {
            XCTFail("Expected authenticated state")
        }
    }

    func testLoginWithFirebase_failure_throwsError() async {
        // Given
        mockAPIClient.mockError = APIError.networkError("Network error")

        // When/Then
        do {
            try await sut.loginWithFirebase(token: "firebase-token")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }

    // MARK: - Logout Tests

    func testLogout_clearsTokens() async {
        // Given
        mockTokenManager.mockAccessToken = "access-token"
        mockTokenManager.mockRefreshToken = "refresh-token"

        // When
        await sut.logout()

        // Then
        XCTAssertTrue(mockTokenManager.clearTokensCalled)
    }

    func testLogout_setsUnauthenticatedState() async {
        // Given - simulate authenticated state
        let authResponse = AuthResponse(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresIn: 3600
        )
        let userProfile = createMockProfile()
        mockAPIClient.mockResponses = [authResponse, userProfile]
        try? await sut.loginWithFirebase(token: "firebase-token")

        // When
        await sut.logout()

        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertEqual(sut.authState, .unauthenticated)
    }

    // MARK: - Auth State Tests

    func testIsAuthenticated_returnsTrueWhenAuthenticated() async throws {
        // Given
        let authResponse = AuthResponse(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresIn: 3600
        )
        let userProfile = createMockProfile()
        mockAPIClient.mockResponses = [authResponse, userProfile]

        // When
        try await sut.loginWithFirebase(token: "firebase-token")

        // Then
        XCTAssertTrue(sut.isAuthenticated)
    }

    func testIsAuthenticated_returnsFalseWhenUnauthenticated() async {
        // Given - fresh auth manager with no tokens
        mockTokenManager.mockAccessToken = nil

        // When
        await sut.logout()

        // Then
        XCTAssertFalse(sut.isAuthenticated)
    }

    func testCurrentUser_returnsUserWhenAuthenticated() async throws {
        // Given
        let authResponse = AuthResponse(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresIn: 3600
        )
        let userProfile = createMockProfile()
        mockAPIClient.mockResponses = [authResponse, userProfile]

        // When
        try await sut.loginWithFirebase(token: "firebase-token")

        // Then
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(sut.currentUser?.id, "user-1")
    }

    func testCurrentUser_returnsNilWhenUnauthenticated() async {
        // Given/When
        await sut.logout()

        // Then
        XCTAssertNil(sut.currentUser)
    }

    // MARK: - Refresh Profile Tests

    func testRefreshUserProfile_updatesCurrentUser() async throws {
        // Given - first login
        let authResponse = AuthResponse(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresIn: 3600
        )
        let initialProfile = createMockProfile()
        mockAPIClient.mockResponses = [authResponse, initialProfile]
        try await sut.loginWithFirebase(token: "firebase-token")

        // Then refresh with updated profile
        let updatedProfile = createMockProfile(
            displayName: "Updated Name",
            bio: "Updated bio",
            level: 10,
            recipeCount: 20,
            logCount: 50,
            followerCount: 200,
            followingCount: 100
        )
        mockAPIClient.mockResponse = updatedProfile

        // When
        try await sut.refreshUserProfile()

        // Then
        XCTAssertEqual(sut.currentUser?.displayName, "Updated Name")
        XCTAssertEqual(sut.currentUser?.level, 10)
    }

    // MARK: - Auth State Publisher Tests

    func testAuthStatePublisher_emitsStateChanges() async throws {
        // Given
        var receivedStates: [AuthState] = []
        sut.authStatePublisher
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)

        let authResponse = AuthResponse(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresIn: 3600
        )
        let userProfile = createMockProfile()
        mockAPIClient.mockResponses = [authResponse, userProfile]

        // When
        try await sut.loginWithFirebase(token: "firebase-token")
        await sut.logout()

        // Then - should have received multiple state changes
        XCTAssertTrue(receivedStates.count >= 2)
        XCTAssertEqual(receivedStates.last, .unauthenticated)
    }

    // MARK: - Helpers

    private func createMockProfile(
        id: String = "user-1",
        username: String = "testuser",
        displayName: String? = "Test User",
        bio: String? = "Test bio",
        level: Int = 5,
        levelProgress: Double = 0.5,
        recipeCount: Int = 10,
        logCount: Int = 25,
        savedCount: Int = 5,
        followerCount: Int = 100,
        followingCount: Int = 50
    ) -> MyProfile {
        let userInfo = UserInfo(
            id: id,
            username: username,
            role: "USER",
            profileImageUrl: nil,
            gender: nil,
            locale: "en",
            defaultCookingStyle: nil,
            measurementPreference: "METRIC",
            followerCount: followerCount,
            followingCount: followingCount,
            recipeCount: recipeCount,
            logCount: logCount,
            level: level,
            levelName: "homeCook",
            totalXp: 500,
            xpForCurrentLevel: 100,
            xpForNextLevel: 200,
            levelProgress: levelProgress,
            bio: bio,
            youtubeUrl: nil,
            instagramHandle: nil
        )
        return MyProfile(
            user: userInfo,
            recipeCount: recipeCount,
            logCount: logCount,
            savedCount: savedCount
        )
    }
}

// MARK: - Mock API Client

class MockAPIClient: APIClientProtocol {
    var mockResponse: Any?
    var mockResponses: [Any] = []
    var mockError: Error?
    private var responseIndex = 0

    func request<T: Decodable>(endpoint: APIEndpoint) async throws -> T {
        if let error = mockError {
            throw error
        }

        let response: Any
        if !mockResponses.isEmpty {
            response = mockResponses[min(responseIndex, mockResponses.count - 1)]
            responseIndex += 1
        } else if let r = mockResponse {
            response = r
        } else {
            throw APIError.unknown
        }

        guard let typedResponse = response as? T else {
            throw APIError.decodingError("Type mismatch")
        }
        return typedResponse
    }

    func request(endpoint: APIEndpoint) async throws {
        if let error = mockError {
            throw error
        }
    }

    func uploadImage(_ imageData: Data, type: String) async throws -> ImageUploadResponse {
        throw APIError.unknown
    }
}
