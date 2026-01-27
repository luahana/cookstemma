import XCTest
@testable import Cookstemma

@MainActor
final class CreateLogViewModelTests: XCTestCase {

    var sut: CreateLogViewModel!
    var mockRepository: MockCookingLogRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockCookingLogRepository()
        sut = CreateLogViewModel(logRepository: mockRepository)
    }

    override func tearDown() async throws {
        sut = nil
        mockRepository = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_hasCorrectDefaults() {
        XCTAssertEqual(sut.state, .idle)
        XCTAssertTrue(sut.photos.isEmpty)
        XCTAssertEqual(sut.rating, 0)
        XCTAssertTrue(sut.content.isEmpty)
        XCTAssertNil(sut.selectedRecipe)
        XCTAssertTrue(sut.hashtags.isEmpty)
        XCTAssertFalse(sut.isPrivate)
    }

    func testInitialState_cannotSubmit() {
        XCTAssertFalse(sut.canSubmit)
    }

    func testInitialState_photosRemainingIsFive() {
        XCTAssertEqual(sut.photosRemaining, 5)
    }

    // MARK: - addPhoto Tests

    func testAddPhoto_addsPhotoToList() {
        // Given
        let image = createMockImage()

        // When
        sut.addPhoto(image)

        // Then
        XCTAssertEqual(sut.photos.count, 1)
    }

    func testAddPhoto_multiplePhotos_addsAll() {
        // When
        for _ in 0..<3 {
            sut.addPhoto(createMockImage())
        }

        // Then
        XCTAssertEqual(sut.photos.count, 3)
        XCTAssertEqual(sut.photosRemaining, 2)
    }

    func testAddPhoto_atMaximum_doesNotAddMore() {
        // Given - add 5 photos (max)
        for _ in 0..<5 {
            sut.addPhoto(createMockImage())
        }
        XCTAssertEqual(sut.photos.count, 5)

        // When - try to add one more
        sut.addPhoto(createMockImage())

        // Then
        XCTAssertEqual(sut.photos.count, 5)
        XCTAssertEqual(sut.photosRemaining, 0)
    }

    // MARK: - removePhoto Tests

    func testRemovePhoto_removesCorrectPhoto() {
        // Given
        sut.addPhoto(createMockImage())
        sut.addPhoto(createMockImage())
        XCTAssertEqual(sut.photos.count, 2)

        // When
        sut.removePhoto(at: 0)

        // Then
        XCTAssertEqual(sut.photos.count, 1)
    }

    func testRemovePhoto_invalidIndex_doesNothing() {
        // Given
        sut.addPhoto(createMockImage())

        // When
        sut.removePhoto(at: 5)

        // Then
        XCTAssertEqual(sut.photos.count, 1)
    }

    // MARK: - selectRecipe Tests

    func testSelectRecipe_setsSelectedRecipe() {
        // Given
        let recipe = createMockRecipeSummary()

        // When
        sut.selectRecipe(recipe)

        // Then
        XCTAssertEqual(sut.selectedRecipe?.id, recipe.id)
    }

    func testSelectRecipe_nil_clearsSelection() {
        // Given
        sut.selectRecipe(createMockRecipeSummary())
        XCTAssertNotNil(sut.selectedRecipe)

        // When
        sut.selectRecipe(nil)

        // Then
        XCTAssertNil(sut.selectedRecipe)
    }

    // MARK: - canSubmit Tests

    func testCanSubmit_withPhotoAndRating_returnsTrue() {
        // When
        sut.addPhoto(createMockImage())
        sut.rating = 4

        // Then
        XCTAssertTrue(sut.canSubmit)
    }

    func testCanSubmit_withoutPhoto_returnsFalse() {
        // When
        sut.rating = 4

        // Then
        XCTAssertFalse(sut.canSubmit)
    }

    func testCanSubmit_withoutRating_returnsFalse() {
        // When
        sut.addPhoto(createMockImage())
        sut.rating = 0

        // Then
        XCTAssertFalse(sut.canSubmit)
    }

    func testCanSubmit_whileSubmitting_returnsFalse() async {
        // Given
        sut.addPhoto(createMockImage())
        sut.rating = 4
        mockRepository.delay = 0.5
        mockRepository.createLogResult = .success(createMockLogDetail())

        // When
        Task {
            await sut.submit()
        }
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then - during submission
        XCTAssertFalse(sut.canSubmit)
    }

    // MARK: - submit Tests

    func testSubmit_success_setsSuccessState() async {
        // Given
        let expectedLog = createMockLogDetail()
        mockRepository.createLogResult = .success(expectedLog)
        sut.addPhoto(createMockImage())
        sut.rating = 4
        sut.content = "Great recipe!"

        // When
        await sut.submit()

        // Then
        if case .success(let log) = sut.state {
            XCTAssertEqual(log.id, expectedLog.id)
        } else {
            XCTFail("Expected success state, got \(sut.state)")
        }
    }

    func testSubmit_failure_setsErrorState() async {
        // Given
        mockRepository.createLogResult = .failure(.networkError("Failed"))
        sut.addPhoto(createMockImage())
        sut.rating = 4

        // When
        await sut.submit()

        // Then
        if case .error(let message) = sut.state {
            XCTAssertTrue(message.contains("Network"))
        } else {
            XCTFail("Expected error state, got \(sut.state)")
        }
    }

    func testSubmit_withoutRequirements_doesNotSubmit() async {
        // Given - no photo, no rating
        XCTAssertFalse(sut.canSubmit)

        // When
        await sut.submit()

        // Then
        XCTAssertEqual(sut.state, .idle)
    }

    func testSubmit_includesAllFields() async {
        // Given
        let recipe = createMockRecipeSummary()
        mockRepository.createLogResult = .success(createMockLogDetail())

        sut.addPhoto(createMockImage())
        sut.rating = 5
        sut.content = "Amazing!"
        sut.selectRecipe(recipe)
        sut.hashtags = ["homecooking", "dinner"]
        sut.isPrivate = true

        // When
        await sut.submit()

        // Then - verify submission happened
        if case .success = sut.state {
            // Success - request was made
        } else {
            XCTFail("Expected success state")
        }
    }

    // MARK: - reset Tests

    func testReset_clearsAllState() async {
        // Given
        sut.addPhoto(createMockImage())
        sut.rating = 4
        sut.content = "Test"
        sut.selectRecipe(createMockRecipeSummary())
        sut.hashtags = ["test"]
        sut.isPrivate = true

        mockRepository.createLogResult = .success(createMockLogDetail())
        await sut.submit()

        // When
        sut.reset()

        // Then
        XCTAssertEqual(sut.state, .idle)
        XCTAssertTrue(sut.photos.isEmpty)
        XCTAssertEqual(sut.rating, 0)
        XCTAssertTrue(sut.content.isEmpty)
        XCTAssertNil(sut.selectedRecipe)
        XCTAssertTrue(sut.hashtags.isEmpty)
        XCTAssertFalse(sut.isPrivate)
    }

    // MARK: - Helpers

    private func createMockImage() -> UIImage {
        UIImage()
    }

    private func createMockRecipeSummary() -> RecipeSummary {
        RecipeSummary(
            id: "recipe-123",
            title: "Test Recipe",
            description: nil,
            coverImageUrl: nil,
            cookingTimeRange: .under15,
            servings: 2,
            cookCount: 50,
            averageRating: 4.0,
            author: UserSummary(
                id: "user-1",
                username: "testuser",
                displayName: "Test User",
                avatarUrl: nil,
                level: 5,
                isFollowing: nil
            ),
            isSaved: false,
            category: nil,
            createdAt: Date()
        )
    }

    private func createMockLogDetail() -> CookingLogDetail {
        CookingLogDetail(
            id: "log-123",
            rating: 4,
            content: "Test content",
            images: [],
            author: UserSummary(
                id: "user-1",
                username: "testuser",
                displayName: "Test User",
                avatarUrl: nil,
                level: 5,
                isFollowing: nil
            ),
            recipe: nil,
            hashtags: [],
            isPrivate: false,
            likeCount: 0,
            commentCount: 0,
            isLiked: false,
            isSaved: false,
            createdAt: Date()
        )
    }
}
