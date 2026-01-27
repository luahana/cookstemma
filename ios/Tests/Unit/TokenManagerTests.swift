import XCTest
@testable import Cookstemma

final class TokenManagerTests: XCTestCase {
    var sut: TestableTokenManager!

    override func setUp() {
        super.setUp()
        sut = TestableTokenManager()
    }

    override func tearDown() {
        sut.clearTokens()
        sut = nil
        super.tearDown()
    }

    // MARK: - Save Tokens Tests

    func testSaveTokens_storesAccessToken() {
        // When
        sut.saveTokens(accessToken: "test-access", refreshToken: "test-refresh", expiresIn: 3600)

        // Then
        XCTAssertEqual(sut.accessToken, "test-access")
    }

    func testSaveTokens_storesRefreshToken() {
        // When
        sut.saveTokens(accessToken: "test-access", refreshToken: "test-refresh", expiresIn: 3600)

        // Then
        XCTAssertEqual(sut.refreshToken, "test-refresh")
    }

    func testSaveTokens_setsAuthenticated() {
        // When
        sut.saveTokens(accessToken: "test-access", refreshToken: "test-refresh", expiresIn: 3600)

        // Then
        XCTAssertTrue(sut.isAuthenticated)
    }

    // MARK: - Clear Tokens Tests

    func testClearTokens_removesAccessToken() {
        // Given
        sut.saveTokens(accessToken: "test-access", refreshToken: "test-refresh", expiresIn: 3600)

        // When
        sut.clearTokens()

        // Then
        XCTAssertNil(sut.accessToken)
    }

    func testClearTokens_removesRefreshToken() {
        // Given
        sut.saveTokens(accessToken: "test-access", refreshToken: "test-refresh", expiresIn: 3600)

        // When
        sut.clearTokens()

        // Then
        XCTAssertNil(sut.refreshToken)
    }

    func testClearTokens_setsNotAuthenticated() {
        // Given
        sut.saveTokens(accessToken: "test-access", refreshToken: "test-refresh", expiresIn: 3600)

        // When
        sut.clearTokens()

        // Then
        XCTAssertFalse(sut.isAuthenticated)
    }

    // MARK: - Token Expiry Tests

    func testIsAuthenticated_returnsFalseWhenTokenExpired() {
        // Given - token that expires immediately
        sut.saveTokens(accessToken: "test-access", refreshToken: "test-refresh", expiresIn: -1)

        // Then
        XCTAssertFalse(sut.isAuthenticated)
    }

    func testIsAuthenticated_returnsTrueWhenTokenNotExpired() {
        // Given
        sut.saveTokens(accessToken: "test-access", refreshToken: "test-refresh", expiresIn: 3600)

        // Then
        XCTAssertTrue(sut.isAuthenticated)
    }

    // MARK: - Initial State Tests

    func testInitialState_hasNoAccessToken() {
        XCTAssertNil(sut.accessToken)
    }

    func testInitialState_hasNoRefreshToken() {
        XCTAssertNil(sut.refreshToken)
    }

    func testInitialState_isNotAuthenticated() {
        XCTAssertFalse(sut.isAuthenticated)
    }

    // MARK: - Update Tokens Tests

    func testSaveTokens_overwritesPreviousTokens() {
        // Given
        sut.saveTokens(accessToken: "old-access", refreshToken: "old-refresh", expiresIn: 3600)

        // When
        sut.saveTokens(accessToken: "new-access", refreshToken: "new-refresh", expiresIn: 7200)

        // Then
        XCTAssertEqual(sut.accessToken, "new-access")
        XCTAssertEqual(sut.refreshToken, "new-refresh")
    }
}

// MARK: - Testable Token Manager

/// A token manager that uses in-memory storage for testing
final class TestableTokenManager: TokenManagerProtocol {
    private var _accessToken: String?
    private var _refreshToken: String?
    private var _expiryDate: Date?

    var accessToken: String? {
        _accessToken
    }

    var refreshToken: String? {
        _refreshToken
    }

    var isAuthenticated: Bool {
        guard let token = _accessToken, let expiry = _expiryDate else {
            return false
        }
        return !token.isEmpty && Date().addingTimeInterval(60) < expiry
    }

    func saveTokens(accessToken: String, refreshToken: String, expiresIn: Int) {
        _accessToken = accessToken
        _refreshToken = refreshToken
        _expiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
    }

    func refreshAccessToken() async throws {
        throw APIError.unauthorized
    }

    func clearTokens() {
        _accessToken = nil
        _refreshToken = nil
        _expiryDate = nil
    }
}
