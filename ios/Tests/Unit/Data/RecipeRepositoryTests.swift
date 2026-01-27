import XCTest
@testable import Cookstemma

final class RecipeRepositoryTests: XCTestCase {

    var sut: RecipeRepository!
    var mockAPIClient: MockAPIClient!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        sut = RecipeRepository(apiClient: mockAPIClient)
    }

    override func tearDown() {
        sut = nil
        mockAPIClient = nil
        super.tearDown()
    }

    // MARK: - getRecipes Tests

    func testGetRecipes_success_returnsPaginatedResponse() async {
        // Given
        let expectedRecipes = createMockRecipes(count: 3)
        let expectedResponse = PaginatedResponse(
            content: expectedRecipes,
            nextCursor: "cursor123",
            hasNext: true
        )
        mockAPIClient.mockResponse = expectedResponse

        // When
        let result = await sut.getRecipes(cursor: nil, filters: nil)

        // Then
        switch result {
        case .success(let response):
            XCTAssertEqual(response.content.count, 3)
            XCTAssertEqual(response.nextCursor, "cursor123")
            XCTAssertTrue(response.hasMore)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetRecipes_withCursor_passesToAPI() async {
        // Given
        mockAPIClient.mockResponse = PaginatedResponse<RecipeSummary>(
            content: [],
            nextCursor: nil,
            hasNext: false
        )

        // When
        _ = await sut.getRecipes(cursor: "test-cursor", filters: nil)

        // Then
        XCTAssertTrue(mockAPIClient.requestCalled)
    }

    func testGetRecipes_withFilters_passesToAPI() async {
        // Given
        let filters = RecipeFilters(
            cookingTimeRange: .under15,
            category: "korean",
            searchQuery: "kimchi",
            sortBy: .newest
        )
        mockAPIClient.mockResponse = PaginatedResponse<RecipeSummary>(
            content: [],
            nextCursor: nil,
            hasNext: false
        )

        // When
        _ = await sut.getRecipes(cursor: nil, filters: filters)

        // Then
        XCTAssertTrue(mockAPIClient.requestCalled)
    }

    func testGetRecipes_networkError_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.networkError("Connection failed")

        // When
        let result = await sut.getRecipes(cursor: nil, filters: nil)

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .networkError("Connection failed"))
        }
    }

    func testGetRecipes_unauthorized_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.unauthorized

        // When
        let result = await sut.getRecipes(cursor: nil, filters: nil)

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .unauthorized)
        }
    }

    // MARK: - getRecipe Tests

    func testGetRecipe_success_returnsDetail() async {
        // Given
        let expectedRecipe = createMockRecipeDetail()
        mockAPIClient.mockResponse = expectedRecipe

        // When
        let result = await sut.getRecipe(id: "recipe-123")

        // Then
        switch result {
        case .success(let recipe):
            XCTAssertEqual(recipe.id, "recipe-123")
            XCTAssertEqual(recipe.title, "Test Recipe")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetRecipe_notFound_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.notFound

        // When
        let result = await sut.getRecipe(id: "non-existent")

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .notFound)
        }
    }

    func testGetRecipe_serverError_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.serverError(500, "Internal server error")

        // When
        let result = await sut.getRecipe(id: "recipe-123")

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .serverError("Internal server error"))
        }
    }

    // MARK: - getRecipeLogs Tests

    func testGetRecipeLogs_success_returnsPaginatedLogs() async {
        // Given
        let expectedLogs = createMockLogs(count: 5)
        let expectedResponse = PaginatedResponse(
            content: expectedLogs,
            nextCursor: "next",
            hasNext: true
        )
        mockAPIClient.mockResponse = expectedResponse

        // When
        let result = await sut.getRecipeLogs(recipeId: "recipe-123", cursor: nil)

        // Then
        switch result {
        case .success(let response):
            XCTAssertEqual(response.content.count, 5)
            XCTAssertTrue(response.hasMore)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - saveRecipe Tests

    func testSaveRecipe_success_returnsVoid() async {
        // Given
        mockAPIClient.mockResponse = EmptyResponse()

        // When
        let result = await sut.saveRecipe(id: "recipe-123")

        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testSaveRecipe_error_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.serverError(400, "Already saved")

        // When
        let result = await sut.saveRecipe(id: "recipe-123")

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .serverError("Already saved"))
        }
    }

    // MARK: - unsaveRecipe Tests

    func testUnsaveRecipe_success_returnsVoid() async {
        // Given
        mockAPIClient.mockResponse = EmptyResponse()

        // When
        let result = await sut.unsaveRecipe(id: "recipe-123")

        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - Error Mapping Tests

    func testErrorMapping_decodingError() async {
        // Given
        mockAPIClient.mockError = APIError.decodingError("Invalid JSON")

        // When
        let result = await sut.getRecipe(id: "recipe-123")

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .decodingError("Invalid JSON"))
        }
    }

    func testErrorMapping_unknownError() async {
        // Given
        mockAPIClient.mockError = NSError(domain: "test", code: -1)

        // When
        let result = await sut.getRecipe(id: "recipe-123")

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .unknown)
        }
    }

    // MARK: - Helpers

    private func createMockRecipes(count: Int) -> [RecipeSummary] {
        (0..<count).map { i in
            RecipeSummary(
                id: "recipe-\(i)",
                title: "Recipe \(i)",
                description: "Description \(i)",
                coverImageUrl: nil,
                cookingTimeRange: .under15,
                servings: 2,
                cookCount: i * 10,
                averageRating: 4.0,
                author: createMockAuthor(),
                isSaved: false,
                category: nil,
                createdAt: Date()
            )
        }
    }

    private func createMockRecipeDetail() -> RecipeDetail {
        RecipeDetail(
            id: "recipe-123",
            title: "Test Recipe",
            description: "Test description",
            images: [],
            cookingTimeRange: .between15And30,
            servings: 4,
            cookCount: 100,
            averageRating: 4.5,
            author: createMockAuthor(),
            isSaved: false,
            ingredients: [],
            steps: [],
            hashtags: [],
            recentLogs: [],
            category: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func createMockLogs(count: Int) -> [CookingLogSummary] {
        (0..<count).map { i in
            CookingLogSummary(
                id: "log-\(i)",
                rating: 4,
                content: "Log content \(i)",
                images: [],
                author: createMockAuthor(),
                recipe: nil,
                likeCount: i * 5,
                commentCount: i,
                isLiked: false,
                isSaved: false,
                createdAt: Date()
            )
        }
    }

    private func createMockAuthor() -> UserSummary {
        UserSummary(
            id: "user-1",
            username: "testuser",
            displayName: "Test User",
            avatarUrl: nil,
            level: 5,
            isFollowing: nil
        )
    }
}

// MARK: - Mock API Client

class MockAPIClient: APIClientProtocol {
    var mockResponse: Any?
    var mockError: Error?
    var requestCalled = false

    func request<T: Decodable>(_ endpoint: any EndpointProtocol) async throws -> T {
        requestCalled = true

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse as? T else {
            throw APIError.decodingError("Mock response type mismatch")
        }

        return response
    }

    func upload<T: Decodable>(_ endpoint: any EndpointProtocol, data: Data, mimeType: String) async throws -> T {
        requestCalled = true

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse as? T else {
            throw APIError.decodingError("Mock response type mismatch")
        }

        return response
    }
}

// MARK: - Empty Response

private struct EmptyResponse: Decodable {}
