import XCTest
@testable import Cookstemma

@MainActor
final class HomeFeedViewModelTests: XCTestCase {

    var sut: HomeFeedViewModel!
    var mockRepository: MockHomeFeedRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockHomeFeedRepository()
        sut = HomeFeedViewModel(logRepository: mockRepository)
    }

    override func tearDown() async throws {
        sut = nil
        mockRepository = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_isIdle() {
        XCTAssertEqual(sut.state, .idle)
        XCTAssertTrue(sut.feedItems.isEmpty)
        XCTAssertFalse(sut.isLoadingMore)
    }

    // MARK: - loadFeed Tests

    func testLoadFeed_setsLoadingState() async {
        // Given
        mockRepository.feedResult = .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
        mockRepository.delay = 0.1

        // When
        sut.loadFeed()

        // Give time for loading state to be set
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Then - should be loading
        XCTAssertEqual(sut.state, .loading)
    }

    func testLoadFeed_success_setsLoadedState() async {
        // Given
        let feedItems = createMockFeedItems(count: 3)
        mockRepository.feedResult = .success(PaginatedResponse(
            content: feedItems,
            nextCursor: "cursor123",
            hasNext: true
        ))

        // When
        await sut.refresh()

        // Then
        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.feedItems.count, 3)
    }

    func testLoadFeed_emptyContent_setsEmptyState() async {
        // Given
        mockRepository.feedResult = .success(PaginatedResponse(
            content: [],
            nextCursor: nil,
            hasNext: false
        ))

        // When
        await sut.refresh()

        // Then
        XCTAssertEqual(sut.state, .empty)
        XCTAssertTrue(sut.feedItems.isEmpty)
    }

    func testLoadFeed_failure_setsErrorState() async {
        // Given
        mockRepository.feedResult = .failure(.networkError("No internet"))

        // When
        await sut.refresh()

        // Then
        if case .error(let message) = sut.state {
            XCTAssertTrue(message.contains("Network error"))
        } else {
            XCTFail("Expected error state, got \(sut.state)")
        }
    }

    // MARK: - Pagination Tests

    func testLoadMoreIfNeeded_loadsMoreWhenNearEnd() async {
        // Given - initial load with 5 items
        let initialItems = createMockFeedItems(count: 5)
        mockRepository.feedResult = .success(PaginatedResponse(
            content: initialItems,
            nextCursor: "cursor1",
            hasNext: true
        ))
        await sut.refresh()

        // Prepare more items for next page
        let moreItems = createMockFeedItems(count: 3, startIndex: 5)
        mockRepository.feedResult = .success(PaginatedResponse(
            content: moreItems,
            nextCursor: "cursor2",
            hasNext: true
        ))

        // When - trigger loadMoreIfNeeded with last item
        let lastItem = sut.feedItems.last!
        sut.loadMoreIfNeeded(currentItem: lastItem)

        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - should have loaded more items
        XCTAssertEqual(sut.feedItems.count, 8)
    }

    func testLoadMoreIfNeeded_doesNotLoadWhenNoMoreItems() async {
        // Given
        mockRepository.feedResult = .success(PaginatedResponse(
            content: createMockFeedItems(count: 2),
            nextCursor: nil,
            hasNext: false
        ))
        await sut.refresh()
        mockRepository.feedCalled = false

        // When - try to load more
        let lastItem = sut.feedItems.last!
        sut.loadMoreIfNeeded(currentItem: lastItem)
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then - should not have called feed again
        XCTAssertFalse(mockRepository.feedCalled)
    }

    func testLoadMoreIfNeeded_doesNotTriggerForEarlyItems() async {
        // Given - load 10 items
        mockRepository.feedResult = .success(PaginatedResponse(
            content: createMockFeedItems(count: 10),
            nextCursor: "cursor",
            hasNext: true
        ))
        await sut.refresh()
        mockRepository.feedCalled = false

        // When - trigger with first item (not near end)
        let firstItem = sut.feedItems.first!
        sut.loadMoreIfNeeded(currentItem: firstItem)
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then - should not trigger load
        XCTAssertFalse(mockRepository.feedCalled)
    }

    // MARK: - Refresh Tests

    func testRefresh_clearsExistingItemsAndReloads() async {
        // Given - initial load
        mockRepository.feedResult = .success(PaginatedResponse(
            content: createMockFeedItems(count: 5),
            nextCursor: "cursor1",
            hasNext: true
        ))
        await sut.refresh()
        XCTAssertEqual(sut.feedItems.count, 5)

        // Prepare new items for refresh
        let newItems = createMockFeedItems(count: 2, startIndex: 100)
        mockRepository.feedResult = .success(PaginatedResponse(
            content: newItems,
            nextCursor: nil,
            hasNext: false
        ))

        // When
        await sut.refresh()

        // Then - should have only new items
        XCTAssertEqual(sut.feedItems.count, 2)
        XCTAssertEqual(sut.feedItems.first?.id, "log-100")
    }

    // MARK: - Helpers

    private func createMockFeedItems(count: Int, startIndex: Int = 0) -> [FeedLogItem] {
        (startIndex..<startIndex + count).map { i in
            FeedLogItem(
                id: "log-\(i)",
                title: "Title \(i)",
                content: "Content \(i)",
                rating: 4,
                thumbnailUrl: nil,
                creatorPublicId: "user-\(i)",
                userName: "user\(i)",
                foodName: "Food \(i)",
                recipeTitle: "Recipe \(i)",
                hashtags: ["tag\(i)"],
                isVariant: false,
                isPrivate: false,
                commentCount: i,
                cookingStyle: nil
            )
        }
    }
}

// MARK: - Mock Repository

class MockHomeFeedRepository: CookingLogRepositoryProtocol {
    var feedResult: RepositoryResult<PaginatedResponse<FeedLogItem>> = .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    var homeFeedResult: RepositoryResult<HomeFeedResponse> = .success(HomeFeedResponse(recentActivity: [], recentRecipes: [], trendingTrees: nil))
    var logDetailResult: RepositoryResult<CookingLogDetail>?
    var userLogsResult: RepositoryResult<PaginatedResponse<CookingLogSummary>>?
    var createLogResult: RepositoryResult<CookingLogDetail>?
    var updateLogResult: RepositoryResult<CookingLogDetail>?
    var deleteResult: RepositoryResult<Void> = .success(())
    var likeResult: RepositoryResult<Void> = .success(())
    var unlikeResult: RepositoryResult<Void> = .success(())
    var saveLogResult: RepositoryResult<Void> = .success(())
    var unsaveLogResult: RepositoryResult<Void> = .success(())

    var feedCalled = false
    var delay: TimeInterval = 0

    func getHomeFeed() async -> RepositoryResult<HomeFeedResponse> {
        return homeFeedResult
    }

    func getFeed(cursor: String?, size: Int) async -> RepositoryResult<PaginatedResponse<FeedLogItem>> {
        feedCalled = true
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        return feedResult
    }

    func getLog(id: String) async -> RepositoryResult<CookingLogDetail> {
        logDetailResult ?? .failure(.notFound)
    }

    func getUserLogs(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<CookingLogSummary>> {
        userLogsResult ?? .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    }

    func createLog(_ request: CreateLogRequest) async -> RepositoryResult<CookingLogDetail> {
        createLogResult ?? .failure(.unknown)
    }

    func updateLog(id: String, _ request: UpdateLogRequest) async -> RepositoryResult<CookingLogDetail> {
        updateLogResult ?? .failure(.unknown)
    }

    func deleteLog(id: String) async -> RepositoryResult<Void> { deleteResult }
    func likeLog(id: String) async -> RepositoryResult<Void> { likeResult }
    func unlikeLog(id: String) async -> RepositoryResult<Void> { unlikeResult }
    func saveLog(id: String) async -> RepositoryResult<Void> { saveLogResult }
    func unsaveLog(id: String) async -> RepositoryResult<Void> { unsaveLogResult }
}
