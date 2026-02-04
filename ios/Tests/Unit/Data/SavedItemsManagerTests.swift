import XCTest
import Combine
@testable import Cookstemma

@MainActor
final class SavedItemsManagerTests: XCTestCase {

    var sut: SavedItemsManager!
    var mockRecipeRepository: MockRecipeRepository!
    var mockLogRepository: MockCookingLogRepository!
    var mockSavedContentRepository: MockSavedContentRepository!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        mockRecipeRepository = MockRecipeRepository()
        mockLogRepository = MockCookingLogRepository()
        mockSavedContentRepository = MockSavedContentRepository()
        sut = SavedItemsManager.createForTesting(
            recipeRepository: mockRecipeRepository,
            logRepository: mockLogRepository,
            savedContentRepository: mockSavedContentRepository
        )
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        sut = nil
        mockRecipeRepository = nil
        mockLogRepository = nil
        mockSavedContentRepository = nil
        cancellables = nil
        try await super.tearDown()
    }

    // MARK: - Toggle Save Recipe Tests

    func testToggleSaveRecipe_save_addsToSavedRecipes() async {
        // Given
        let recipe = createMockRecipeSummary(id: "recipe-1")
        // Mock the API to return the saved recipe after save
        mockSavedContentRepository.getSavedRecipesResult = .success(
            PaginatedResponse(content: [recipe], nextCursor: nil, hasNext: false)
        )
        XCTAssertFalse(sut.isRecipeSaved("recipe-1"))
        XCTAssertEqual(sut.savedRecipes.count, 0)

        // When
        await sut.toggleSaveRecipe(id: "recipe-1", summary: recipe)

        // Then
        XCTAssertTrue(sut.isRecipeSaved("recipe-1"))
        XCTAssertEqual(sut.savedRecipes.count, 1)
        XCTAssertEqual(sut.savedRecipes.first?.id, "recipe-1")
        XCTAssertTrue(mockRecipeRepository.saveRecipeCalled)
    }

    func testToggleSaveRecipe_unsave_removesFromSavedRecipes() async {
        // Given - first save the recipe
        let recipe = createMockRecipeSummary(id: "recipe-1")
        // Mock the API to return the recipe after first save
        mockSavedContentRepository.getSavedRecipesResult = .success(
            PaginatedResponse(content: [recipe], nextCursor: nil, hasNext: false)
        )
        await sut.toggleSaveRecipe(id: "recipe-1", summary: recipe)
        XCTAssertTrue(sut.isRecipeSaved("recipe-1"))

        // Now mock the API to return empty after unsave
        mockSavedContentRepository.getSavedRecipesResult = .success(
            PaginatedResponse(content: [], nextCursor: nil, hasNext: false)
        )

        // When - toggle again to unsave
        await sut.toggleSaveRecipe(id: "recipe-1", summary: nil)

        // Then
        XCTAssertFalse(sut.isRecipeSaved("recipe-1"))
        XCTAssertEqual(sut.savedRecipes.count, 0)
        XCTAssertTrue(mockRecipeRepository.unsaveRecipeCalled)
    }

    func testToggleSaveRecipe_apiFailure_revertsState() async {
        // Given
        let recipe = createMockRecipeSummary(id: "recipe-1")
        mockRecipeRepository.saveRecipeResult = .failure(.networkError("Connection failed"))
        XCTAssertFalse(sut.isRecipeSaved("recipe-1"))

        // When
        await sut.toggleSaveRecipe(id: "recipe-1", summary: recipe)

        // Then - state should be reverted since API failed
        XCTAssertFalse(sut.isRecipeSaved("recipe-1"))
        XCTAssertEqual(sut.savedRecipes.count, 0)
    }

    func testToggleSaveRecipe_saveWithoutSummary_fetchesFromApi() async {
        // Given
        let recipe = createMockRecipeSummary(id: "recipe-1")
        // When saving without summary, the recipe should be fetched from API
        mockSavedContentRepository.getSavedRecipesResult = .success(
            PaginatedResponse(content: [recipe], nextCursor: nil, hasNext: false)
        )
        XCTAssertFalse(sut.isRecipeSaved("recipe-1"))

        // When - save without providing summary
        await sut.toggleSaveRecipe(id: "recipe-1", summary: nil)

        // Then - recipe should be populated from API fetch
        XCTAssertTrue(sut.isRecipeSaved("recipe-1"))
        XCTAssertEqual(sut.savedRecipes.count, 1)
    }

    func testToggleSaveRecipe_duplicateSave_doesNotDuplicate() async {
        // Given
        let recipe = createMockRecipeSummary(id: "recipe-1")
        mockSavedContentRepository.getSavedRecipesResult = .success(
            PaginatedResponse(content: [recipe], nextCursor: nil, hasNext: false)
        )
        await sut.toggleSaveRecipe(id: "recipe-1", summary: recipe)
        XCTAssertEqual(sut.savedRecipes.count, 1)

        // When - try to save again (simulate race condition)
        sut.updateSavedRecipes([recipe])
        // Mock empty response for unsave
        mockSavedContentRepository.getSavedRecipesResult = .success(
            PaginatedResponse(content: [], nextCursor: nil, hasNext: false)
        )
        await sut.toggleSaveRecipe(id: "recipe-1", summary: recipe)

        // Then - should unsave (toggle behavior)
        XCTAssertFalse(sut.isRecipeSaved("recipe-1"))
    }

    // MARK: - Toggle Save Log Tests

    func testToggleSaveLog_save_addsToSavedLogs() async {
        // Given
        let log = createMockFeedLogItem(id: "log-1")
        // Mock the API to return the saved log after save
        mockSavedContentRepository.getSavedLogsResult = .success(
            PaginatedResponse(content: [log], nextCursor: nil, hasNext: false)
        )
        XCTAssertFalse(sut.isLogSaved("log-1"))
        XCTAssertEqual(sut.savedLogs.count, 0)

        // When
        await sut.toggleSaveLog(id: "log-1", logItem: log)

        // Then
        XCTAssertTrue(sut.isLogSaved("log-1"))
        XCTAssertEqual(sut.savedLogs.count, 1)
        XCTAssertEqual(sut.savedLogs.first?.id, "log-1")
        XCTAssertTrue(mockLogRepository.saveLogCalled)
    }

    func testToggleSaveLog_unsave_removesFromSavedLogs() async {
        // Given - first save the log
        let log = createMockFeedLogItem(id: "log-1")
        // Mock the API to return the log after first save
        mockSavedContentRepository.getSavedLogsResult = .success(
            PaginatedResponse(content: [log], nextCursor: nil, hasNext: false)
        )
        await sut.toggleSaveLog(id: "log-1", logItem: log)
        XCTAssertTrue(sut.isLogSaved("log-1"))

        // Now mock the API to return empty after unsave
        mockSavedContentRepository.getSavedLogsResult = .success(
            PaginatedResponse(content: [], nextCursor: nil, hasNext: false)
        )

        // When - toggle again to unsave
        await sut.toggleSaveLog(id: "log-1", logItem: nil)

        // Then
        XCTAssertFalse(sut.isLogSaved("log-1"))
        XCTAssertEqual(sut.savedLogs.count, 0)
        XCTAssertTrue(mockLogRepository.unsaveLogCalled)
    }

    func testToggleSaveLog_apiFailure_revertsState() async {
        // Given
        let log = createMockFeedLogItem(id: "log-1")
        mockLogRepository.saveLogResult = .failure(.networkError("Connection failed"))
        XCTAssertFalse(sut.isLogSaved("log-1"))

        // When
        await sut.toggleSaveLog(id: "log-1", logItem: log)

        // Then - state should be reverted since API failed
        XCTAssertFalse(sut.isLogSaved("log-1"))
        XCTAssertEqual(sut.savedLogs.count, 0)
    }

    // MARK: - Fetch Tests

    func testFetchSavedRecipes_success_populatesState() async {
        // Given
        let recipes = [
            createMockRecipeSummary(id: "recipe-1"),
            createMockRecipeSummary(id: "recipe-2")
        ]
        mockSavedContentRepository.getSavedRecipesResult = .success(
            PaginatedResponse(content: recipes, nextCursor: nil, hasNext: false)
        )

        // When
        await sut.fetchSavedRecipes()

        // Then
        XCTAssertEqual(sut.savedRecipes.count, 2)
        XCTAssertTrue(sut.isRecipeSaved("recipe-1"))
        XCTAssertTrue(sut.isRecipeSaved("recipe-2"))
    }

    func testFetchSavedLogs_success_populatesState() async {
        // Given
        let logs = [
            createMockFeedLogItem(id: "log-1"),
            createMockFeedLogItem(id: "log-2")
        ]
        mockSavedContentRepository.getSavedLogsResult = .success(
            PaginatedResponse(content: logs, nextCursor: nil, hasNext: false)
        )

        // When
        await sut.fetchSavedLogs()

        // Then
        XCTAssertEqual(sut.savedLogs.count, 2)
        XCTAssertTrue(sut.isLogSaved("log-1"))
        XCTAssertTrue(sut.isLogSaved("log-2"))
    }

    func testFetchAllSavedContent_success_populatesBoth() async {
        // Given
        let recipes = [createMockRecipeSummary(id: "recipe-1")]
        let logs = [createMockFeedLogItem(id: "log-1")]
        mockSavedContentRepository.getSavedRecipesResult = .success(
            PaginatedResponse(content: recipes, nextCursor: nil, hasNext: false)
        )
        mockSavedContentRepository.getSavedLogsResult = .success(
            PaginatedResponse(content: logs, nextCursor: nil, hasNext: false)
        )

        // When
        await sut.fetchAllSavedContent()

        // Then
        XCTAssertEqual(sut.savedRecipes.count, 1)
        XCTAssertEqual(sut.savedLogs.count, 1)
    }

    // MARK: - Reset Tests

    func testReset_clearsAllState() async {
        // Given - populate some state
        let recipe = createMockRecipeSummary(id: "recipe-1")
        let log = createMockFeedLogItem(id: "log-1")
        mockSavedContentRepository.getSavedRecipesResult = .success(
            PaginatedResponse(content: [recipe], nextCursor: nil, hasNext: false)
        )
        mockSavedContentRepository.getSavedLogsResult = .success(
            PaginatedResponse(content: [log], nextCursor: nil, hasNext: false)
        )
        await sut.toggleSaveRecipe(id: "recipe-1", summary: recipe)
        await sut.toggleSaveLog(id: "log-1", logItem: log)
        XCTAssertEqual(sut.savedRecipes.count, 1)
        XCTAssertEqual(sut.savedLogs.count, 1)

        // When
        sut.reset()

        // Then
        XCTAssertEqual(sut.savedRecipes.count, 0)
        XCTAssertEqual(sut.savedLogs.count, 0)
        XCTAssertFalse(sut.isRecipeSaved("recipe-1"))
        XCTAssertFalse(sut.isLogSaved("log-1"))
    }

    // MARK: - Update Methods Tests

    func testUpdateSavedRecipes_replacesExistingList() async {
        // Given
        let oldRecipe = createMockRecipeSummary(id: "old-recipe")
        mockSavedContentRepository.getSavedRecipesResult = .success(
            PaginatedResponse(content: [oldRecipe], nextCursor: nil, hasNext: false)
        )
        await sut.toggleSaveRecipe(id: "old-recipe", summary: oldRecipe)
        XCTAssertTrue(sut.isRecipeSaved("old-recipe"))

        // When
        let newRecipes = [
            createMockRecipeSummary(id: "new-recipe-1"),
            createMockRecipeSummary(id: "new-recipe-2")
        ]
        sut.updateSavedRecipes(newRecipes)

        // Then
        XCTAssertEqual(sut.savedRecipes.count, 2)
        XCTAssertFalse(sut.isRecipeSaved("old-recipe"))
        XCTAssertTrue(sut.isRecipeSaved("new-recipe-1"))
        XCTAssertTrue(sut.isRecipeSaved("new-recipe-2"))
    }

    func testUpdateSavedLogs_replacesExistingList() async {
        // Given
        let oldLog = createMockFeedLogItem(id: "old-log")
        mockSavedContentRepository.getSavedLogsResult = .success(
            PaginatedResponse(content: [oldLog], nextCursor: nil, hasNext: false)
        )
        await sut.toggleSaveLog(id: "old-log", logItem: oldLog)
        XCTAssertTrue(sut.isLogSaved("old-log"))

        // When
        let newLogs = [
            createMockFeedLogItem(id: "new-log-1"),
            createMockFeedLogItem(id: "new-log-2")
        ]
        sut.updateSavedLogs(newLogs)

        // Then
        XCTAssertEqual(sut.savedLogs.count, 2)
        XCTAssertFalse(sut.isLogSaved("old-log"))
        XCTAssertTrue(sut.isLogSaved("new-log-1"))
        XCTAssertTrue(sut.isLogSaved("new-log-2"))
    }

    // MARK: - Combine Publisher Tests

    func testSavedRecipesPublisher_emitsOnChange() async {
        // Given
        var receivedRecipes: [[RecipeSummary]] = []
        let expectation = XCTestExpectation(description: "Received updates")
        let recipe = createMockRecipeSummary(id: "recipe-1")
        mockSavedContentRepository.getSavedRecipesResult = .success(
            PaginatedResponse(content: [recipe], nextCursor: nil, hasNext: false)
        )

        sut.$savedRecipes
            .dropFirst() // Skip initial empty value
            .sink { recipes in
                receivedRecipes.append(recipes)
                if receivedRecipes.count >= 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        await sut.toggleSaveRecipe(id: "recipe-1", summary: recipe)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertGreaterThanOrEqual(receivedRecipes.count, 1)
    }

    func testSavedLogsPublisher_emitsOnChange() async {
        // Given
        var receivedLogs: [[FeedLogItem]] = []
        let expectation = XCTestExpectation(description: "Received updates")
        let log = createMockFeedLogItem(id: "log-1")
        mockSavedContentRepository.getSavedLogsResult = .success(
            PaginatedResponse(content: [log], nextCursor: nil, hasNext: false)
        )

        sut.$savedLogs
            .dropFirst() // Skip initial empty value
            .sink { logs in
                receivedLogs.append(logs)
                if receivedLogs.count >= 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        await sut.toggleSaveLog(id: "log-1", logItem: log)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertGreaterThanOrEqual(receivedLogs.count, 1)
    }

    // MARK: - Helper Methods

    private func createMockRecipeSummary(id: String) -> RecipeSummary {
        RecipeSummary(
            id: id,
            title: "Test Recipe \(id)",
            description: "A test recipe",
            foodName: "Test Food",
            cookingStyle: "US",
            userName: "testuser",
            thumbnail: "https://example.com/thumb.jpg",
            variantCount: 0,
            logCount: 10,
            servings: 2,
            cookingTimeRange: "MIN_15_TO_30",
            hashtags: [],
            isPrivate: false,
            isSaved: false
        )
    }

    private func createMockFeedLogItem(id: String) -> FeedLogItem {
        FeedLogItem(
            id: id,
            title: "Test Log \(id)",
            content: "Test content",
            rating: 4,
            thumbnailUrl: "https://example.com/thumb.jpg",
            creatorPublicId: "user-1",
            userName: "testuser",
            foodName: "Test Food",
            recipeTitle: "Test Recipe",
            hashtags: [],
            isVariant: false,
            isPrivate: false,
            commentCount: 0,
            cookingStyle: "US"
        )
    }
}


