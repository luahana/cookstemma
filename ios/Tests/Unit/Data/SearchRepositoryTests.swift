import XCTest
@testable import Cookstemma

final class SearchRepositoryTests: XCTestCase {

    var sut: SearchRepository!
    var mockAPIClient: SearchTestAPIClient!

    override func setUp() {
        super.setUp()
        mockAPIClient = SearchTestAPIClient()
        sut = SearchRepository(apiClient: mockAPIClient)
    }

    override func tearDown() {
        sut = nil
        mockAPIClient = nil
        super.tearDown()
    }

    // MARK: - searchRecipes Tests

    func testSearchRecipes_success_callsUnifiedSearchEndpoint() async {
        // Given
        let mockResponse = createMockUnifiedSearchResponse(
            items: [createMockRecipeSearchItem(id: "recipe1", title: "Kimchi Recipe")]
        )
        mockAPIClient.mockResponse = mockResponse

        // When
        let result = await sut.searchRecipes(query: "kimchi", filters: nil, cursor: nil)

        // Then
        XCTAssertTrue(mockAPIClient.requestCalled)
        switch result {
        case .success(let response):
            XCTAssertEqual(response.content.count, 1)
            XCTAssertEqual(response.content[0].id, "recipe1")
            XCTAssertEqual(response.content[0].title, "Kimchi Recipe")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testSearchRecipes_filtersOutNonRecipeItems() async {
        // Given
        let mockResponse = createMockUnifiedSearchResponse(
            items: [
                createMockRecipeSearchItem(id: "recipe1", title: "Recipe 1"),
                createMockLogSearchItem(id: "log1", content: "Log content"),
                createMockRecipeSearchItem(id: "recipe2", title: "Recipe 2")
            ]
        )
        mockAPIClient.mockResponse = mockResponse

        // When
        let result = await sut.searchRecipes(query: "test", filters: nil, cursor: nil)

        // Then
        switch result {
        case .success(let response):
            XCTAssertEqual(response.content.count, 2)
            XCTAssertEqual(response.content[0].id, "recipe1")
            XCTAssertEqual(response.content[1].id, "recipe2")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testSearchRecipes_preservesPaginationInfo() async {
        // Given
        let mockResponse = createMockUnifiedSearchResponse(
            items: [createMockRecipeSearchItem(id: "recipe1", title: "Recipe")],
            nextCursor: "next_page",
            hasNext: true
        )
        mockAPIClient.mockResponse = mockResponse

        // When
        let result = await sut.searchRecipes(query: "test", filters: nil, cursor: nil)

        // Then
        switch result {
        case .success(let response):
            XCTAssertEqual(response.nextCursor, "next_page")
            XCTAssertTrue(response.hasNext)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testSearchRecipes_error_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.networkError("Connection failed")

        // When
        let result = await sut.searchRecipes(query: "test", filters: nil, cursor: nil)

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .networkError("Connection failed"))
        }
    }

    // MARK: - searchLogs Tests

    func testSearchLogs_success_callsUnifiedSearchEndpoint() async {
        // Given
        let mockResponse = createMockUnifiedSearchResponse(
            items: [createMockLogSearchItem(id: "log1", content: "My cooking log")]
        )
        mockAPIClient.mockResponse = mockResponse

        // When
        let result = await sut.searchLogs(query: "cooking", cursor: nil)

        // Then
        XCTAssertTrue(mockAPIClient.requestCalled)
        switch result {
        case .success(let response):
            XCTAssertEqual(response.content.count, 1)
            XCTAssertEqual(response.content[0].id, "log1")
            XCTAssertEqual(response.content[0].content, "My cooking log")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testSearchLogs_filtersOutNonLogItems() async {
        // Given
        let mockResponse = createMockUnifiedSearchResponse(
            items: [
                createMockLogSearchItem(id: "log1", content: "Log 1"),
                createMockRecipeSearchItem(id: "recipe1", title: "Recipe"),
                createMockLogSearchItem(id: "log2", content: "Log 2")
            ]
        )
        mockAPIClient.mockResponse = mockResponse

        // When
        let result = await sut.searchLogs(query: "test", cursor: nil)

        // Then
        switch result {
        case .success(let response):
            XCTAssertEqual(response.content.count, 2)
            XCTAssertEqual(response.content[0].id, "log1")
            XCTAssertEqual(response.content[1].id, "log2")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testSearchLogs_transformsLogPostSummaryToCookingLogSummary() async {
        // Given
        let mockResponse = createMockUnifiedSearchResponse(
            items: [createMockLogSearchItem(
                id: "log1",
                content: "Test content",
                userName: "testuser",
                rating: 5,
                thumbnailUrl: "http://example.com/thumb.jpg"
            )]
        )
        mockAPIClient.mockResponse = mockResponse

        // When
        let result = await sut.searchLogs(query: "test", cursor: nil)

        // Then
        switch result {
        case .success(let response):
            let log = response.content[0]
            XCTAssertEqual(log.id, "log1")
            XCTAssertEqual(log.content, "Test content")
            XCTAssertEqual(log.rating, 5)
            XCTAssertEqual(log.author.username, "testuser")
            XCTAssertFalse(log.images.isEmpty)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - searchUsers Tests

    func testSearchUsers_success_callsUnifiedSearchEndpoint() async {
        // Given
        let mockResponse = createMockUnifiedSearchResponse(
            items: [createMockUserSearchItem(id: "user1", username: "john_doe")]
        )
        mockAPIClient.mockResponse = mockResponse

        // When
        let result = await sut.searchUsers(query: "john", cursor: nil)

        // Then
        XCTAssertTrue(mockAPIClient.requestCalled)
        switch result {
        case .success(let response):
            XCTAssertEqual(response.content.count, 1)
            XCTAssertEqual(response.content[0].id, "user1")
            XCTAssertEqual(response.content[0].username, "john_doe")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testSearchUsers_filtersOutNonUserItems() async {
        // Given
        let mockResponse = createMockUnifiedSearchResponse(
            items: [
                createMockUserSearchItem(id: "user1", username: "user1"),
                createMockRecipeSearchItem(id: "recipe1", title: "Recipe"),
                createMockUserSearchItem(id: "user2", username: "user2")
            ]
        )
        mockAPIClient.mockResponse = mockResponse

        // When
        let result = await sut.searchUsers(query: "test", cursor: nil)

        // Then
        switch result {
        case .success(let response):
            XCTAssertEqual(response.content.count, 2)
            XCTAssertEqual(response.content[0].id, "user1")
            XCTAssertEqual(response.content[1].id, "user2")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - unified search Tests

    func testSearch_success_returnsUnifiedResponse() async {
        // Given
        let mockResponse = createMockUnifiedSearchResponse(
            items: [
                createMockRecipeSearchItem(id: "recipe1", title: "Recipe"),
                createMockLogSearchItem(id: "log1", content: "Log")
            ]
        )
        mockAPIClient.mockResponse = mockResponse

        // When
        let result = await sut.search(query: "test", type: nil, cursor: nil)

        // Then
        switch result {
        case .success(let response):
            XCTAssertEqual(response.content.count, 2)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - Helpers

    private func createMockUnifiedSearchResponse(
        items: [SearchResultItem],
        nextCursor: String? = nil,
        hasNext: Bool = false
    ) -> UnifiedSearchResponse {
        UnifiedSearchResponse(
            content: items,
            counts: SearchCountsResponse(
                recipes: items.filter { if case .recipe = $0.data { return true }; return false }.count,
                logs: items.filter { if case .log = $0.data { return true }; return false }.count,
                hashtags: items.filter { if case .hashtag = $0.data { return true }; return false }.count,
                total: items.count
            ),
            page: 0,
            size: 20,
            totalElements: items.count,
            totalPages: 1,
            hasNext: hasNext,
            nextCursor: nextCursor
        )
    }

    private func createMockRecipeSearchItem(id: String, title: String) -> SearchResultItem {
        SearchResultItem(
            type: "RECIPE",
            relevanceScore: 1.0,
            data: .recipe(RecipeSummary(
                id: id,
                title: title,
                description: nil,
                foodName: "Test Food",
                cookingStyle: nil,
                userName: "testuser",
                thumbnail: nil,
                variantCount: 0,
                logCount: 0,
                servings: nil,
                cookingTimeRange: nil,
                hashtags: [],
                isPrivate: false
            ))
        )
    }

    private func createMockLogSearchItem(
        id: String,
        content: String,
        userName: String = "testuser",
        rating: Int = 5,
        thumbnailUrl: String? = nil
    ) -> SearchResultItem {
        SearchResultItem(
            type: "LOG",
            relevanceScore: 0.9,
            data: .log(LogPostSummaryResponse(
                id: id,
                title: nil,
                content: content,
                rating: rating,
                thumbnailUrl: thumbnailUrl,
                creatorPublicId: "creator1",
                userName: userName,
                foodName: "Test Food",
                recipeTitle: nil,
                hashtags: [],
                isVariant: false,
                isPrivate: false,
                commentCount: 0,
                locale: nil
            ))
        )
    }

    private func createMockUserSearchItem(id: String, username: String) -> SearchResultItem {
        SearchResultItem(
            type: "USER",
            relevanceScore: 0.8,
            data: .user(UserSummary(
                id: id,
                username: username,
                displayName: "Test User",
                avatarUrl: nil,
                level: 1,
                isFollowing: false
            ))
        )
    }
}

// MARK: - Search Test API Client

final class SearchTestAPIClient: APIClientProtocol {
    var mockResponse: Any?
    var mockError: Error?
    var requestCalled = false

    func request<T: Decodable>(_ endpoint: any APIEndpoint) async throws -> T {
        requestCalled = true

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse as? T else {
            throw APIError.decodingError("Mock response type mismatch")
        }

        return response
    }

    func upload<T: Decodable>(_ endpoint: any APIEndpoint, data: Data, mimeType: String) async throws -> T {
        requestCalled = true

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse as? T else {
            throw APIError.decodingError("Mock response type mismatch")
        }

        return response
    }

    func request(_ endpoint: any APIEndpoint) async throws {
        requestCalled = true
        if let error = mockError { throw error }
    }

    func uploadImage(_ imageData: Data, type: String) async throws -> ImageUploadResponse {
        throw APIError.unknown
    }
}
