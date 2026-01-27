import XCTest
@testable import Cookstemma

final class CookingLogRepositoryTests: XCTestCase {

    var sut: CookingLogRepository!
    var mockAPIClient: MockAPIClient!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        sut = CookingLogRepository(apiClient: mockAPIClient)
    }

    override func tearDown() {
        sut = nil
        mockAPIClient = nil
        super.tearDown()
    }

    // MARK: - getFeed Tests

    func testGetFeed_success_returnsFeedItems() async {
        // Given
        let expectedItems = [createMockFeedLogItem(), createMockFeedLogItem(id: "log-456")]
        let expectedResponse = PaginatedResponse(
            content: expectedItems,
            nextCursor: "cursor123",
            hasNext: true
        )
        mockAPIClient.mockResponse = expectedResponse

        // When
        let result = await sut.getFeed(cursor: nil, size: 20)

        // Then
        switch result {
        case .success(let response):
            XCTAssertEqual(response.content.count, 2)
            XCTAssertTrue(response.hasMore)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetFeed_withCursor_fetches() async {
        // Given
        mockAPIClient.mockResponse = PaginatedResponse<FeedLogItem>(
            content: [],
            nextCursor: nil,
            hasNext: false
        )

        // When
        _ = await sut.getFeed(cursor: "page2", size: 20)

        // Then
        XCTAssertTrue(mockAPIClient.requestCalled)
    }

    func testGetFeed_networkError_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.networkError("No internet")

        // When
        let result = await sut.getFeed(cursor: nil, size: 20)

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .networkError("No internet"))
        }
    }

    // MARK: - getLog Tests

    func testGetLog_success_returnsDetail() async {
        // Given
        let expectedLog = createMockLogDetail()
        mockAPIClient.mockResponse = expectedLog

        // When
        let result = await sut.getLog(id: "log-123")

        // Then
        switch result {
        case .success(let log):
            XCTAssertEqual(log.id, "log-123")
            XCTAssertEqual(log.rating, 4)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetLog_notFound_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.notFound

        // When
        let result = await sut.getLog(id: "non-existent")

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .notFound)
        }
    }

    // MARK: - getUserLogs Tests

    func testGetUserLogs_success_returnsPaginatedLogs() async {
        // Given
        let logs = [createMockLogSummary(), createMockLogSummary()]
        let expectedResponse = PaginatedResponse(
            content: logs,
            nextCursor: "next",
            hasNext: true
        )
        mockAPIClient.mockResponse = expectedResponse

        // When
        let result = await sut.getUserLogs(userId: "user-123", cursor: nil)

        // Then
        switch result {
        case .success(let response):
            XCTAssertEqual(response.content.count, 2)
            XCTAssertTrue(response.hasMore)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - createLog Tests

    func testCreateLog_success_returnsCreatedLog() async {
        // Given
        let expectedLog = createMockLogDetail()
        mockAPIClient.mockResponse = expectedLog

        let request = CreateLogRequest(
            rating: 5,
            content: "Great experience!",
            imageIds: ["img-1", "img-2"],
            recipeId: "recipe-123",
            hashtags: ["homecooking"],
            isPrivate: false
        )

        // When
        let result = await sut.createLog(request)

        // Then
        switch result {
        case .success(let log):
            XCTAssertEqual(log.id, "log-123")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testCreateLog_validationError_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.serverError(400, "Rating is required")

        let request = CreateLogRequest(
            rating: 0, // Invalid
            content: nil,
            imageIds: [],
            recipeId: nil,
            hashtags: [],
            isPrivate: false
        )

        // When
        let result = await sut.createLog(request)

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .serverError("Rating is required"))
        }
    }

    // MARK: - updateLog Tests

    func testUpdateLog_success_returnsUpdatedLog() async {
        // Given
        let expectedLog = createMockLogDetail()
        mockAPIClient.mockResponse = expectedLog

        let request = UpdateLogRequest(
            rating: 4,
            content: "Updated content",
            imageIds: nil,
            recipeId: nil,
            hashtags: nil,
            isPrivate: nil
        )

        // When
        let result = await sut.updateLog(id: "log-123", request)

        // Then
        switch result {
        case .success(let log):
            XCTAssertEqual(log.id, "log-123")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - deleteLog Tests

    func testDeleteLog_success_returnsVoid() async {
        // Given
        mockAPIClient.mockResponse = EmptyResponse()

        // When
        let result = await sut.deleteLog(id: "log-123")

        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testDeleteLog_unauthorized_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.unauthorized

        // When
        let result = await sut.deleteLog(id: "log-123")

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .unauthorized)
        }
    }

    // MARK: - likeLog Tests

    func testLikeLog_success_returnsVoid() async {
        // Given
        mockAPIClient.mockResponse = EmptyResponse()

        // When
        let result = await sut.likeLog(id: "log-123")

        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testLikeLog_alreadyLiked_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.serverError(409, "Already liked")

        // When
        let result = await sut.likeLog(id: "log-123")

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .serverError("Already liked"))
        }
    }

    // MARK: - unlikeLog Tests

    func testUnlikeLog_success_returnsVoid() async {
        // Given
        mockAPIClient.mockResponse = EmptyResponse()

        // When
        let result = await sut.unlikeLog(id: "log-123")

        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - saveLog Tests

    func testSaveLog_success_returnsVoid() async {
        // Given
        mockAPIClient.mockResponse = EmptyResponse()

        // When
        let result = await sut.saveLog(id: "log-123")

        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - unsaveLog Tests

    func testUnsaveLog_success_returnsVoid() async {
        // Given
        mockAPIClient.mockResponse = EmptyResponse()

        // When
        let result = await sut.unsaveLog(id: "log-123")

        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - Helpers

    private func createMockFeedLogItem(id: String = "log-123") -> FeedLogItem {
        FeedLogItem(
            id: id,
            title: "Test Log",
            content: "Test log content",
            rating: 4,
            thumbnailUrl: nil,
            creatorPublicId: "user-1",
            userName: "testuser",
            foodName: "Test Food",
            recipeTitle: "Test Recipe",
            hashtags: ["test"],
            isVariant: false,
            isPrivate: false,
            commentCount: 3,
            cookingStyle: nil
        )
    }

    private func createMockLogSummary() -> CookingLogSummary {
        CookingLogSummary(
            id: "log-123",
            rating: 4,
            content: "Test log content",
            images: [],
            author: createMockAuthor(),
            recipe: nil,
            likeCount: 10,
            commentCount: 3,
            isLiked: false,
            isSaved: false,
            createdAt: Date()
        )
    }

    private func createMockLogDetail() -> CookingLogDetail {
        CookingLogDetail(
            id: "log-123",
            title: nil,
            rating: 4,
            content: "Test log content",
            logImages: [],
            linkedRecipe: nil,
            commentCount: 3,
            isSavedByCurrentUser: false,
            hashtagObjects: [],
            isPrivate: false,
            creatorPublicId: "user-1",
            userName: "testuser",
            createdAt: Date()
        )
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

// MARK: - Empty Response

private struct EmptyResponse: Decodable {}
