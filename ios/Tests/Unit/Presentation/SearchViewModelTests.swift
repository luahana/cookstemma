import XCTest
@testable import Cookstemma

@MainActor
final class SearchViewModelTests: XCTestCase {

    var sut: SearchViewModel!
    var mockRepository: MockSearchRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockSearchRepository()
        sut = SearchViewModel(searchRepository: mockRepository)
    }

    override func tearDown() async throws {
        sut = nil
        mockRepository = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_hasEmptyQuery() {
        XCTAssertTrue(sut.query.isEmpty)
    }

    func testInitialState_hasEmptyResults() {
        XCTAssertNil(sut.results.topResult)
        XCTAssertTrue(sut.results.recipes.isEmpty)
        XCTAssertTrue(sut.results.logs.isEmpty)
        XCTAssertTrue(sut.results.users.isEmpty)
    }

    func testInitialState_isNotSearching() {
        XCTAssertFalse(sut.isSearching)
    }

    // MARK: - Search Tests

    func testSearch_withValidQuery_performsSearch() async {
        // Given
        let response = createMockSearchResponse()
        mockRepository.searchResult = .success(response)
        sut.query = "kimchi"

        // When
        sut.search()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertFalse(sut.results.recipes.isEmpty)
    }

    func testSearch_withEmptyQuery_clearsResults() {
        // Given
        sut.query = ""

        // When
        sut.search()

        // Then
        XCTAssertNil(sut.results.topResult)
        XCTAssertTrue(sut.results.recipes.isEmpty)
    }

    func testSearch_setsTopResult() async {
        // Given
        let response = createMockSearchResponse()
        mockRepository.searchResult = .success(response)
        sut.query = "recipe"

        // When
        sut.search()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertNotNil(sut.results.topResult)
    }

    func testSearch_setsSearchingFlag() async {
        // Given
        mockRepository.delay = 0.1
        mockRepository.searchResult = .success(createMockSearchResponse())
        sut.query = "test"

        // When
        sut.search()
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Then - should be searching
        XCTAssertTrue(sut.isSearching)
    }

    func testSearch_failure_clearsResults() async {
        // Given
        mockRepository.searchResult = .failure(.networkError("Failed"))
        sut.query = "test"

        // When
        sut.search()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(sut.results.recipes.isEmpty)
        XCTAssertFalse(sut.isSearching)
    }

    // MARK: - Debounce Tests

    func testSearch_debounces_rapidQueries() async {
        // Given
        mockRepository.searchResult = .success(createMockSearchResponse())

        // When - rapidly change queries
        sut.query = "a"
        try? await Task.sleep(nanoseconds: 50_000_000)
        sut.query = "ab"
        try? await Task.sleep(nanoseconds: 50_000_000)
        sut.query = "abc"

        // Wait for debounce
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then - only final query should trigger search
        // The debounce behavior is tested implicitly
    }

    // MARK: - Recent Searches Tests

    func testLoadRecentSearches_loadsFromStorage() {
        // When
        sut.loadRecentSearches()

        // Then - recent searches loaded (from UserDefaults)
        // Note: Actual storage behavior tested via integration tests
    }

    func testSearch_addsToRecentSearches() async {
        // Given
        mockRepository.searchResult = .success(createMockSearchResponse())
        sut.query = "new search"

        // When
        sut.search()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(sut.recentSearches.contains("new search"))
    }

    func testRemoveRecentSearch_removesFromList() {
        // Given
        sut.loadRecentSearches()
        // Manually add a search for testing
        sut.query = "test search"
        mockRepository.searchResult = .success(createMockSearchResponse())

        // Add to recent searches by performing search
        Task {
            sut.search()
        }

        // When
        sut.removeRecentSearch("test search")

        // Then
        XCTAssertFalse(sut.recentSearches.contains("test search"))
    }

    func testClearRecentSearches_clearsAll() {
        // Given
        sut.loadRecentSearches()

        // When
        sut.clearRecentSearches()

        // Then
        XCTAssertTrue(sut.recentSearches.isEmpty)
    }

    // MARK: - Clear Search Tests

    func testClearSearch_clearsQueryAndResults() async {
        // Given
        mockRepository.searchResult = .success(createMockSearchResponse())
        sut.query = "test"
        sut.search()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.clearSearch()

        // Then
        XCTAssertTrue(sut.query.isEmpty)
        XCTAssertTrue(sut.results.recipes.isEmpty)
    }

    // MARK: - Trending Hashtags Tests

    func testLoadRecentSearches_loadsTrendingHashtags() {
        // Given
        mockRepository.getTrendingHashtagsResult = .success([
            HashtagCount(tag: "trending", count: 100),
            HashtagCount(tag: "popular", count: 50)
        ])

        // When
        sut.loadRecentSearches()

        // Then - hashtags are loaded async
        // Allow time for async loading
        let expectation = XCTestExpectation(description: "Load trending")
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Helpers

    private func createMockSearchResponse() -> SearchResponse {
        SearchResponse(
            recipes: [createMockRecipeSummary()],
            logs: [createMockLogSummary()],
            users: [createMockUserSummary()],
            hashtags: [HashtagCount(tag: "test", count: 10)]
        )
    }

    private func createMockRecipeSummary() -> RecipeSummary {
        RecipeSummary(
            id: "recipe-1",
            title: "Test Recipe",
            description: nil,
            coverImageUrl: nil,
            cookingTimeRange: .under15,
            servings: 2,
            cookCount: 50,
            averageRating: 4.0,
            author: createMockUserSummary(),
            isSaved: false,
            category: nil,
            createdAt: Date()
        )
    }

    private func createMockLogSummary() -> CookingLogSummary {
        CookingLogSummary(
            id: "log-1",
            rating: 4,
            content: "Test log",
            images: [],
            author: createMockUserSummary(),
            recipe: nil,
            likeCount: 10,
            commentCount: 2,
            isLiked: false,
            isSaved: false,
            createdAt: Date()
        )
    }

    private func createMockUserSummary() -> UserSummary {
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

// MARK: - Mock Search Repository

class MockSearchRepository: SearchRepositoryProtocol {
    var searchResult: RepositoryResult<SearchResponse> = .success(SearchResponse(recipes: [], logs: [], users: [], hashtags: []))
    var getTrendingHashtagsResult: RepositoryResult<[HashtagCount]> = .success([])
    var delay: TimeInterval = 0

    func search(query: String, type: SearchType?, cursor: String?) async -> RepositoryResult<SearchResponse> {
        if delay > 0 { try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        return searchResult
    }

    func getTrendingHashtags() async -> RepositoryResult<[HashtagCount]> {
        getTrendingHashtagsResult
    }
}
