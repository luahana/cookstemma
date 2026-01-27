import XCTest
@testable import Cookstemma

final class APIClientTests: XCTestCase {
    var sut: APIClient!
    var mockURLSession: MockURLSession!
    var mockTokenManager: MockTokenManager!

    override func setUp() {
        super.setUp()
        mockURLSession = MockURLSession()
        mockTokenManager = MockTokenManager()
        sut = APIClient(
            baseURL: URL(string: "https://api.test.com")!,
            session: mockURLSession,
            tokenManager: mockTokenManager
        )
    }

    override func tearDown() {
        sut = nil
        mockURLSession = nil
        mockTokenManager = nil
        super.tearDown()
    }

    // MARK: - Successful Response Tests

    func testRequest_withValidResponse_decodesSuccessfully() async throws {
        // Given
        let expectedUser = UserSummary(
            id: "123",
            username: "testuser",
            displayName: "Test User",
            avatarUrl: nil,
            level: 5
        )
        let responseData = try JSONEncoder().encode(expectedUser)
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.test.com/users/123")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        mockURLSession.mockData = responseData

        // When
        let result: UserSummary = try await sut.request(
            endpoint: TestEndpoint.getUser(id: "123")
        )

        // Then
        XCTAssertEqual(result.id, expectedUser.id)
        XCTAssertEqual(result.username, expectedUser.username)
    }

    func testRequest_withValidResponse_addsAuthHeader() async throws {
        // Given
        mockTokenManager.mockAccessToken = "test-token"
        let responseData = "{}".data(using: .utf8)!
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.test.com/test")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        mockURLSession.mockData = responseData

        // When
        _ = try? await sut.request(endpoint: TestEndpoint.testEndpoint) as EmptyResponse

        // Then
        let authHeader = mockURLSession.lastRequest?.value(forHTTPHeaderField: "Authorization")
        XCTAssertEqual(authHeader, "Bearer test-token")
    }

    // MARK: - Error Handling Tests

    func testRequest_with401Response_triggersTokenRefresh() async {
        // Given
        mockTokenManager.mockAccessToken = "expired-token"
        mockTokenManager.mockRefreshToken = "refresh-token"

        // First call returns 401
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.test.com/test")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )
        mockURLSession.mockData = Data()

        // When
        do {
            _ = try await sut.request(endpoint: TestEndpoint.testEndpoint) as EmptyResponse
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertTrue(mockTokenManager.refreshTokenCalled)
        }
    }

    func testRequest_withNetworkError_throwsNetworkError() async {
        // Given
        mockURLSession.mockError = URLError(.notConnectedToInternet)

        // When/Then
        do {
            _ = try await sut.request(endpoint: TestEndpoint.testEndpoint) as EmptyResponse
            XCTFail("Expected error to be thrown")
        } catch let error as APIError {
            if case .networkError = error {
                // Success
            } else {
                XCTFail("Expected networkError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequest_with404Response_throwsNotFoundError() async {
        // Given
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.test.com/test")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )
        mockURLSession.mockData = Data()

        // When/Then
        do {
            _ = try await sut.request(endpoint: TestEndpoint.testEndpoint) as EmptyResponse
            XCTFail("Expected error to be thrown")
        } catch let error as APIError {
            if case .notFound = error {
                // Success
            } else {
                XCTFail("Expected notFound, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequest_with500Response_throwsServerError() async {
        // Given
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.test.com/test")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        mockURLSession.mockData = Data()

        // When/Then
        do {
            _ = try await sut.request(endpoint: TestEndpoint.testEndpoint) as EmptyResponse
            XCTFail("Expected error to be thrown")
        } catch let error as APIError {
            if case .serverError = error {
                // Success
            } else {
                XCTFail("Expected serverError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Pagination Tests

    func testRequest_withPaginatedResponse_parsesCursor() async throws {
        // Given
        let response = PaginatedResponse(
            items: [
                UserSummary(id: "1", username: "user1", displayName: nil, avatarUrl: nil, level: 1)
            ],
            nextCursor: "cursor-123",
            hasNext: true
        )
        let responseData = try JSONEncoder().encode(response)
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.test.com/users")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        mockURLSession.mockData = responseData

        // When
        let result: PaginatedResponse<UserSummary> = try await sut.request(
            endpoint: TestEndpoint.getUsers(cursor: nil)
        )

        // Then
        XCTAssertEqual(result.nextCursor, "cursor-123")
        XCTAssertTrue(result.hasMore)
        XCTAssertEqual(result.items.count, 1)
    }

    // MARK: - Request Building Tests

    func testRequest_withQueryParameters_buildsCorrectURL() async throws {
        // Given
        let responseData = "{}".data(using: .utf8)!
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.test.com/test")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        mockURLSession.mockData = responseData

        // When
        _ = try? await sut.request(
            endpoint: TestEndpoint.getUsers(cursor: "abc123")
        ) as EmptyResponse

        // Then
        let url = mockURLSession.lastRequest?.url
        XCTAssertTrue(url?.absoluteString.contains("cursor=abc123") == true)
    }

    func testRequest_withPostBody_sendsJSONBody() async throws {
        // Given
        let responseData = "{}".data(using: .utf8)!
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.test.com/test")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        mockURLSession.mockData = responseData

        // When
        _ = try? await sut.request(
            endpoint: TestEndpoint.createItem(name: "Test Item")
        ) as EmptyResponse

        // Then
        let request = mockURLSession.lastRequest
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertNotNil(request?.httpBody)
    }
}

// MARK: - Test Helpers

enum TestEndpoint: APIEndpoint {
    case testEndpoint
    case getUser(id: String)
    case getUsers(cursor: String?)
    case createItem(name: String)

    var path: String {
        switch self {
        case .testEndpoint:
            return "/test"
        case .getUser(let id):
            return "/users/\(id)"
        case .getUsers:
            return "/users"
        case .createItem:
            return "/items"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .testEndpoint, .getUser, .getUsers:
            return .get
        case .createItem:
            return .post
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getUsers(let cursor):
            guard let cursor = cursor else { return nil }
            return [URLQueryItem(name: "cursor", value: cursor)]
        default:
            return nil
        }
    }

    var body: Encodable? {
        switch self {
        case .createItem(let name):
            return ["name": name]
        default:
            return nil
        }
    }

    var requiresAuth: Bool {
        true
    }
}

struct EmptyResponse: Decodable {}

// MARK: - Mock Classes

class MockURLSession: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var lastRequest: URLRequest?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request

        if let error = mockError {
            throw error
        }

        guard let data = mockData, let response = mockResponse else {
            throw URLError(.unknown)
        }

        return (data, response)
    }
}

class MockTokenManager: TokenManagerProtocol {
    var mockAccessToken: String?
    var mockRefreshToken: String?
    var refreshTokenCalled = false
    var clearTokensCalled = false

    var accessToken: String? {
        mockAccessToken
    }

    var refreshToken: String? {
        mockRefreshToken
    }

    var isAuthenticated: Bool {
        mockAccessToken != nil
    }

    func saveTokens(accessToken: String, refreshToken: String, expiresIn: Int) {
        mockAccessToken = accessToken
        mockRefreshToken = refreshToken
    }

    func refreshAccessToken() async throws {
        refreshTokenCalled = true
        throw APIError.unauthorized
    }

    func clearTokens() {
        clearTokensCalled = true
        mockAccessToken = nil
        mockRefreshToken = nil
    }
}
