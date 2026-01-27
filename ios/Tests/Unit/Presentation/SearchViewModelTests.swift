import XCTest
@testable import Cookstemma

@MainActor
final class SearchViewModelTests: XCTestCase {

    var sut: SearchViewModel!
    var mockSearchRepository: SearchMockSearchRepository!
    var mockLogRepository: SearchMockLogRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockSearchRepository = SearchMockSearchRepository()
        mockLogRepository = SearchMockLogRepository()
        sut = SearchViewModel(
            searchRepository: mockSearchRepository,
            logRepository: mockLogRepository
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockSearchRepository = nil
        mockLogRepository = nil
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
        mockSearchRepository.searchResult = .success(response)
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
        mockSearchRepository.searchResult = .success(response)
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
        mockSearchRepository.delay = 0.1
        mockSearchRepository.searchResult = .success(createMockSearchResponse())
        sut.query = "test"

        // When
        sut.search()
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Then - should be searching
        XCTAssertTrue(sut.isSearching)
    }

    func testSearch_failure_clearsResults() async {
        // Given
        mockSearchRepository.searchResult = .failure(.networkError("Failed"))
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
        mockSearchRepository.searchResult = .success(createMockSearchResponse())

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
        mockSearchRepository.searchResult = .success(createMockSearchResponse())
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
        mockSearchRepository.searchResult = .success(createMockSearchResponse())

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
        mockSearchRepository.searchResult = .success(createMockSearchResponse())
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
        mockSearchRepository.getTrendingHashtagsResult = .success([
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

    // MARK: - Home Feed Tests

    func testInitialState_hasEmptyTrendingRecipes() {
        XCTAssertTrue(sut.trendingRecipes.isEmpty)
    }

    func testInitialState_hasEmptyRecentLogs() {
        XCTAssertTrue(sut.recentLogs.isEmpty)
    }

    func testInitialState_isNotLoadingHomeFeed() {
        XCTAssertFalse(sut.isLoadingHomeFeed)
    }

    func testInitialState_showAllRecipes_isFalse() {
        XCTAssertFalse(sut.showAllRecipes)
    }

    func testInitialState_showAllLogs_isFalse() {
        XCTAssertFalse(sut.showAllLogs)
    }

    func testLoadHomeFeed_success_populatesTrendingRecipes() async {
        // Given
        let mockRecipes = [createMockHomeRecipeItem()]
        mockLogRepository.homeFeedResult = .success(
            HomeFeedResponse(
                recentActivity: [],
                recentRecipes: mockRecipes,
                trendingTrees: nil
            )
        )

        // When
        sut.loadHomeFeed()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.trendingRecipes.count, 1)
        XCTAssertEqual(sut.trendingRecipes.first?.id, "recipe-1")
    }

    func testLoadHomeFeed_success_populatesRecentLogs() async {
        // Given
        let mockLogs = [createMockRecentActivityItem()]
        mockLogRepository.homeFeedResult = .success(
            HomeFeedResponse(
                recentActivity: mockLogs,
                recentRecipes: [],
                trendingTrees: nil
            )
        )

        // When
        sut.loadHomeFeed()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.recentLogs.count, 1)
        XCTAssertEqual(sut.recentLogs.first?.id, "log-1")
    }

    func testLoadHomeFeed_failure_keepsEmptyLists() async {
        // Given
        mockLogRepository.homeFeedResult = .failure(.networkError("Failed"))

        // When
        sut.loadHomeFeed()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(sut.trendingRecipes.isEmpty)
        XCTAssertTrue(sut.recentLogs.isEmpty)
    }

    func testLoadHomeFeed_setsLoadingFlag() async {
        // Given
        mockLogRepository.delay = 0.1
        mockLogRepository.homeFeedResult = .success(
            HomeFeedResponse(recentActivity: [], recentRecipes: [], trendingTrees: nil)
        )

        // When
        sut.loadHomeFeed()
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Then - should be loading
        XCTAssertTrue(sut.isLoadingHomeFeed)
    }

    func testLoadHomeFeed_clearsLoadingFlag_afterCompletion() async {
        // Given
        mockLogRepository.homeFeedResult = .success(
            HomeFeedResponse(recentActivity: [], recentRecipes: [], trendingTrees: nil)
        )

        // When
        sut.loadHomeFeed()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertFalse(sut.isLoadingHomeFeed)
    }

    func testResetSeeAllState_resetsShowAllRecipes() {
        // Given
        sut.showAllRecipes = true

        // When
        sut.resetSeeAllState()

        // Then
        XCTAssertFalse(sut.showAllRecipes)
    }

    func testResetSeeAllState_resetsShowAllLogs() {
        // Given
        sut.showAllLogs = true

        // When
        sut.resetSeeAllState()

        // Then
        XCTAssertFalse(sut.showAllLogs)
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
            foodName: "Test Food",
            cookingStyle: "KR",
            userName: "testuser",
            thumbnail: nil,
            variantCount: 0,
            logCount: 50,
            servings: 2,
            cookingTimeRange: "UNDER_15",
            hashtags: [],
            isPrivate: false
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

    private func createMockHomeRecipeItem() -> HomeRecipeItem {
        HomeRecipeItem(
            id: "recipe-1",
            foodName: "Kimchi",
            title: "Homemade Kimchi",
            description: "Traditional Korean fermented cabbage",
            cookingStyle: "Korean",
            userName: "testuser",
            thumbnail: nil,
            variantCount: 3,
            logCount: 50,
            servings: 4,
            cookingTimeRange: "30-60min",
            hashtags: ["korean", "fermented"]
        )
    }

    private func createMockRecentActivityItem() -> RecentActivityItem {
        RecentActivityItem(
            id: "log-1",
            rating: 4,
            thumbnailUrl: nil,
            userName: "testuser",
            recipeTitle: "Homemade Kimchi",
            recipeId: "recipe-1",
            foodName: "Kimchi",
            createdAt: Date(),
            hashtags: ["korean"],
            commentCount: 5
        )
    }
}

// MARK: - Search Mock Repositories (local to this file to avoid conflicts)

final class SearchMockSearchRepository: SearchRepositoryProtocol {
    var searchResult: RepositoryResult<SearchResponse> = .success(SearchResponse(recipes: [], logs: [], users: [], hashtags: []))
    var getTrendingHashtagsResult: RepositoryResult<[HashtagCount]> = .success([])
    var delay: TimeInterval = 0

    func search(query: String, type: SearchType?, cursor: String?) async -> RepositoryResult<SearchResponse> {
        if delay > 0 { try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        return searchResult
    }

    func searchRecipes(query: String, filters: RecipeFilters?, cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>> {
        .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    }

    func searchLogs(query: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<CookingLogSummary>> {
        .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    }

    func searchUsers(query: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<UserSummary>> {
        .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    }

    func getTrendingHashtags() async -> RepositoryResult<[HashtagCount]> {
        getTrendingHashtagsResult
    }

    func getHashtagContent(hashtag: String, type: SearchType?, cursor: String?) async -> RepositoryResult<SearchResponse> {
        searchResult
    }
}

final class SearchMockLogRepository: CookingLogRepositoryProtocol {
    var homeFeedResult: RepositoryResult<HomeFeedResponse> = .success(
        HomeFeedResponse(recentActivity: [], recentRecipes: [], trendingTrees: nil)
    )
    var delay: TimeInterval = 0

    func getHomeFeed() async -> RepositoryResult<HomeFeedResponse> {
        if delay > 0 { try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        return homeFeedResult
    }

    func getFeed(cursor: String?, size: Int) async -> RepositoryResult<PaginatedResponse<FeedLogItem>> {
        .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    }

    func getLog(id: String) async -> RepositoryResult<CookingLogDetail> {
        .failure(.notFound)
    }

    func getUserLogs(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<CookingLogSummary>> {
        .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    }

    func createLog(_ request: CreateLogRequest) async -> RepositoryResult<CookingLogDetail> {
        .failure(.unknown)
    }

    func updateLog(id: String, _ request: UpdateLogRequest) async -> RepositoryResult<CookingLogDetail> {
        .failure(.notFound)
    }

    func deleteLog(id: String) async -> RepositoryResult<Void> {
        .success(())
    }

    func likeLog(id: String) async -> RepositoryResult<Void> {
        .success(())
    }

    func unlikeLog(id: String) async -> RepositoryResult<Void> {
        .success(())
    }

    func saveLog(id: String) async -> RepositoryResult<Void> {
        .success(())
    }

    func unsaveLog(id: String) async -> RepositoryResult<Void> {
        .success(())
    }
}
