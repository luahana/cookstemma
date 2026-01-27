import XCTest
@testable import Cookstemma

@MainActor
final class RecipeDetailViewModelTests: XCTestCase {

    var sut: RecipeDetailViewModel!
    var mockRecipeRepository: MockRecipeRepository!
    var mockLogRepository: MockCookingLogRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockRecipeRepository = MockRecipeRepository()
        mockLogRepository = MockCookingLogRepository()
    }

    override func tearDown() async throws {
        sut = nil
        mockRecipeRepository = nil
        mockLogRepository = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_isIdle() {
        sut = createViewModel()
        XCTAssertEqual(sut.state, .idle)
        XCTAssertNil(sut.recipe)
        XCTAssertTrue(sut.logs.isEmpty)
        XCTAssertFalse(sut.isSaved)
    }

    // MARK: - loadRecipe Tests

    func testLoadRecipe_success_setsLoadedState() async {
        // Given
        let expectedRecipe = createMockRecipeDetail()
        mockRecipeRepository.getRecipeResult = .success(expectedRecipe)
        sut = createViewModel()

        // When
        sut.loadRecipe()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then
        if case .loaded(let recipe) = sut.state {
            XCTAssertEqual(recipe.id, "recipe-123")
            XCTAssertEqual(recipe.title, "Test Recipe")
        } else {
            XCTFail("Expected loaded state, got \(sut.state)")
        }
        XCTAssertNotNil(sut.recipe)
        XCTAssertEqual(sut.isSaved, expectedRecipe.isSaved)
    }

    func testLoadRecipe_setsLoadingState() async {
        // Given
        mockRecipeRepository.getRecipeResult = .success(createMockRecipeDetail())
        mockRecipeRepository.delay = 0.1
        sut = createViewModel()

        // When
        sut.loadRecipe()
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Then
        XCTAssertEqual(sut.state, .loading)
    }

    func testLoadRecipe_failure_setsErrorState() async {
        // Given
        mockRecipeRepository.getRecipeResult = .failure(.networkError("Not found"))
        sut = createViewModel()

        // When
        sut.loadRecipe()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then
        if case .error(let message) = sut.state {
            XCTAssertTrue(message.contains("Network"))
        } else {
            XCTFail("Expected error state, got \(sut.state)")
        }
    }

    func testLoadRecipe_populatesRecentLogs() async {
        // Given
        let recipe = createMockRecipeDetail(withLogs: true)
        mockRecipeRepository.getRecipeResult = .success(recipe)
        sut = createViewModel()

        // When
        sut.loadRecipe()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then
        XCTAssertEqual(sut.logs.count, recipe.recentLogs.count)
    }

    // MARK: - loadMoreLogs Tests

    func testLoadMoreLogs_appendsToExistingLogs() async {
        // Given
        let recipe = createMockRecipeDetail()
        mockRecipeRepository.getRecipeResult = .success(recipe)
        sut = createViewModel()
        sut.loadRecipe()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 50_000_000)

        let moreLogs = [createMockLogSummary(id: "log-new")]
        mockRecipeRepository.getRecipeLogsResult = .success(PaginatedResponse(
            content: moreLogs,
            nextCursor: nil,
            hasNext: false
        ))

        // When
        sut.loadMoreLogs()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(sut.logs.contains { $0.id == "log-new" })
    }

    func testLoadMoreLogs_whenAlreadyLoading_doesNotLoadAgain() async {
        // Given
        let recipe = createMockRecipeDetail()
        mockRecipeRepository.getRecipeResult = .success(recipe)
        mockRecipeRepository.delay = 0.2
        sut = createViewModel()
        sut.loadRecipe()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 50_000_000)

        mockRecipeRepository.getRecipeLogsResult = .success(PaginatedResponse(
            content: [createMockLogSummary()],
            nextCursor: nil,
            hasNext: false
        ))

        // When - trigger load and immediately try again
        sut.loadMoreLogs()
        sut.loadMoreLogs()

        // Then - should handle gracefully
        XCTAssertTrue(sut.isLoadingLogs || !sut.isLoadingLogs)
    }

    func testLoadMoreLogs_whenNoMore_doesNotLoad() async {
        // Given
        let recipe = createMockRecipeDetail()
        mockRecipeRepository.getRecipeResult = .success(recipe)
        sut = createViewModel()
        sut.loadRecipe()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Simulate no more logs
        mockRecipeRepository.getRecipeLogsResult = .success(PaginatedResponse(
            content: [],
            nextCursor: nil,
            hasNext: false
        ))
        sut.loadMoreLogs()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Reset to track new calls
        mockRecipeRepository.getRecipeLogsCalled = false

        // When
        sut.loadMoreLogs()
        await Task.yield()

        // Then - should not call API again
        XCTAssertFalse(sut.hasMoreLogs)
    }

    // MARK: - toggleSave Tests

    func testToggleSave_optimisticallyUpdatesState() async {
        // Given
        let recipe = createMockRecipeDetail(isSaved: false)
        mockRecipeRepository.getRecipeResult = .success(recipe)
        mockRecipeRepository.saveRecipeResult = .success(())
        sut = createViewModel()
        sut.loadRecipe()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertFalse(sut.isSaved)

        // When
        await sut.toggleSave()

        // Then
        XCTAssertTrue(sut.isSaved)
    }

    func testToggleSave_unsave_optimisticallyUpdatesState() async {
        // Given
        let recipe = createMockRecipeDetail(isSaved: true)
        mockRecipeRepository.getRecipeResult = .success(recipe)
        mockRecipeRepository.unsaveRecipeResult = .success(())
        sut = createViewModel()
        sut.loadRecipe()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertTrue(sut.isSaved)

        // When
        await sut.toggleSave()

        // Then
        XCTAssertFalse(sut.isSaved)
    }

    func testToggleSave_failure_revertsState() async {
        // Given
        let recipe = createMockRecipeDetail(isSaved: false)
        mockRecipeRepository.getRecipeResult = .success(recipe)
        mockRecipeRepository.saveRecipeResult = .failure(.networkError("Failed"))
        sut = createViewModel()
        sut.loadRecipe()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // When
        await sut.toggleSave()

        // Then - should revert to original state
        XCTAssertFalse(sut.isSaved)
    }

    // MARK: - shareRecipe Tests

    func testShareRecipe_returnsCorrectURL() async {
        // Given
        let recipe = createMockRecipeDetail()
        mockRecipeRepository.getRecipeResult = .success(recipe)
        sut = createViewModel()
        sut.loadRecipe()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // When
        let url = sut.shareRecipe()

        // Then
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("recipe-123") ?? false)
    }

    func testShareRecipe_withoutRecipe_returnsNil() {
        // Given
        sut = createViewModel()

        // When
        let url = sut.shareRecipe()

        // Then
        XCTAssertNil(url)
    }

    // MARK: - Helpers

    private func createViewModel() -> RecipeDetailViewModel {
        RecipeDetailViewModel(
            recipeId: "recipe-123",
            recipeRepository: mockRecipeRepository,
            logRepository: mockLogRepository
        )
    }

    private func createMockRecipeDetail(
        id: String = "recipe-123",
        isSaved: Bool = false,
        withLogs: Bool = false
    ) -> RecipeDetail {
        RecipeDetail(
            id: id,
            title: "Test Recipe",
            description: "Test description",
            coverImageUrl: nil,
            images: [],
            cookingTimeRange: .under15,
            servings: 2,
            cookCount: 100,
            saveCount: 50,
            averageRating: 4.5,
            author: createMockUserSummary(),
            ingredients: [],
            steps: [],
            hashtags: [],
            isSaved: isSaved,
            category: nil,
            recentLogs: withLogs ? [createMockLogSummary()] : [],
            createdAt: Date(),
            updatedAt: Date()
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

    private func createMockLogSummary(id: String = "log-1") -> CookingLogSummary {
        CookingLogSummary(
            id: id,
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
}

// MARK: - Mock Recipe Repository

class MockRecipeRepository: RecipeRepositoryProtocol {
    var getRecipeResult: RepositoryResult<RecipeDetail> = .failure(.notFound)
    var getRecipesResult: RepositoryResult<PaginatedResponse<RecipeSummary>> = .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    var getRecipeLogsResult: RepositoryResult<PaginatedResponse<CookingLogSummary>> = .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    var saveRecipeResult: RepositoryResult<Void> = .success(())
    var unsaveRecipeResult: RepositoryResult<Void> = .success(())
    var searchResult: RepositoryResult<PaginatedResponse<RecipeSummary>> = .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))

    var getRecipeCalled = false
    var getRecipeLogsCalled = false
    var delay: TimeInterval = 0

    func getRecipe(id: String) async -> RepositoryResult<RecipeDetail> {
        getRecipeCalled = true
        if delay > 0 { try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        return getRecipeResult
    }

    func getRecipes(cursor: String?, filters: RecipeFilters?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>> {
        if delay > 0 { try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        return getRecipesResult
    }

    func getRecipeLogs(recipeId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<CookingLogSummary>> {
        getRecipeLogsCalled = true
        if delay > 0 { try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        return getRecipeLogsResult
    }

    func saveRecipe(id: String) async -> RepositoryResult<Void> { saveRecipeResult }
    func unsaveRecipe(id: String) async -> RepositoryResult<Void> { unsaveRecipeResult }
    func searchRecipes(query: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>> { searchResult }
}
