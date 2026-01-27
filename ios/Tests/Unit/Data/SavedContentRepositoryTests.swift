import XCTest
@testable import Cookstemma

final class SavedContentRepositoryTests: XCTestCase {

    var sut: SavedContentRepository!
    var mockAPIClient: SavedContentTestAPIClient!

    override func setUp() {
        super.setUp()
        mockAPIClient = SavedContentTestAPIClient()
        sut = SavedContentRepository(apiClient: mockAPIClient)
    }

    override func tearDown() {
        sut = nil
        mockAPIClient = nil
        super.tearDown()
    }

    // MARK: - Get Saved Recipes Tests

    func testGetSavedRecipes_success_returnsRecipes() async {
        // Given
        let response = PaginatedResponse<RecipeSummary>(content: [], nextCursor: nil, hasNext: false)
        mockAPIClient.result = response

        // When
        let result = await sut.getSavedRecipes(cursor: nil)

        // Then
        switch result {
        case .success(let paginatedResponse):
            XCTAssertEqual(paginatedResponse.content.count, 0)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testGetSavedRecipes_networkError_returnsNetworkError() async {
        // Given
        mockAPIClient.error = APIError.networkError("Connection failed")

        // When
        let result = await sut.getSavedRecipes(cursor: nil)

        // Then
        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            if case .networkError = error {
                // Success
            } else {
                XCTFail("Expected network error")
            }
        }
    }

    func testGetSavedRecipes_unauthorized_returnsUnauthorized() async {
        // Given
        mockAPIClient.error = APIError.unauthorized

        // When
        let result = await sut.getSavedRecipes(cursor: nil)

        // Then
        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            XCTAssertEqual(error, .unauthorized)
        }
    }

    // MARK: - Get Saved Logs Tests

    func testGetSavedLogs_success_returnsLogs() async {
        // Given
        let response = PaginatedResponse<CookingLogSummary>(content: [], nextCursor: nil, hasNext: false)
        mockAPIClient.result = response

        // When
        let result = await sut.getSavedLogs(cursor: nil)

        // Then
        switch result {
        case .success(let paginatedResponse):
            XCTAssertEqual(paginatedResponse.content.count, 0)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testGetSavedLogs_notFound_returnsNotFound() async {
        // Given
        mockAPIClient.error = APIError.notFound

        // When
        let result = await sut.getSavedLogs(cursor: nil)

        // Then
        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            XCTAssertEqual(error, .notFound)
        }
    }

    // MARK: - Pagination Tests

    func testGetSavedRecipes_pagination_returnsNextCursor() async {
        // Given
        let response = PaginatedResponse<RecipeSummary>(content: [], nextCursor: "next-page", hasNext: true)
        mockAPIClient.result = response

        // When
        let result = await sut.getSavedRecipes(cursor: nil)

        // Then
        switch result {
        case .success(let paginatedResponse):
            XCTAssertEqual(paginatedResponse.nextCursor, "next-page")
            XCTAssertTrue(paginatedResponse.hasMore)
        case .failure:
            XCTFail("Expected success")
        }
    }
}

// MARK: - Test API Client (specific to this test file)

class SavedContentTestAPIClient: APIClientProtocol {
    var result: Any?
    var error: APIError?
    var lastEndpoint: Any?

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        lastEndpoint = endpoint
        if let error = error {
            throw error
        }
        if let result = result as? T {
            return result
        }
        throw APIError.unknown
    }

    func request(_ endpoint: APIEndpoint) async throws {
        lastEndpoint = endpoint
        if let error = error {
            throw error
        }
    }
}
