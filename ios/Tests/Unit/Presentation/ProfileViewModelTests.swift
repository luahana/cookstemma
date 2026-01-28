import XCTest
@testable import Cookstemma

@MainActor
final class ProfileViewModelTests: XCTestCase {

    var sut: ProfileViewModel!
    var mockUserRepository: MockUserRepository!
    var mockLogRepository: MockCookingLogRepository!
    var mockSavedContentRepository: MockSavedContentRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockUserRepository = MockUserRepository()
        mockLogRepository = MockCookingLogRepository()
        mockSavedContentRepository = MockSavedContentRepository()
    }

    override func tearDown() async throws {
        sut = nil
        mockUserRepository = nil
        mockLogRepository = nil
        mockSavedContentRepository = nil
        try await super.tearDown()
    }

    // MARK: - Load Own Profile Tests

    func testLoadProfile_withNilUserId_isOwnProfile() {
        // Given
        sut = ProfileViewModel(
            userId: nil,
            userRepository: mockUserRepository,
            logRepository: mockLogRepository,
            savedContentRepository: mockSavedContentRepository
        )

        // Then
        XCTAssertTrue(sut.isOwnProfile)
    }

    func testLoadProfile_withUserId_isNotOwnProfile() {
        // Given
        sut = ProfileViewModel(
            userId: "user-other",
            userRepository: mockUserRepository,
            logRepository: mockLogRepository,
            savedContentRepository: mockSavedContentRepository
        )

        // Then
        XCTAssertFalse(sut.isOwnProfile)
    }

    func testLoadProfile_ownProfile_loadsMyProfile() async {
        // Given
        let myProfile = createMockMyProfile()
        mockUserRepository.getMyProfileResult = .success(myProfile)
        sut = ProfileViewModel(
            userId: nil,
            userRepository: mockUserRepository,
            logRepository: mockLogRepository,
            savedContentRepository: mockSavedContentRepository
        )

        // When
        sut.loadProfile()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertNotNil(sut.myProfile)
        XCTAssertEqual(sut.myProfile?.username, "testuser")
        if case .loaded = sut.state {
            // Success
        } else {
            XCTFail("Expected loaded state")
        }
    }

    func testLoadProfile_otherUser_loadsUserProfile() async {
        // Given
        let userProfile = createMockUserProfile()
        mockUserRepository.getUserProfileResult = .success(userProfile)
        sut = ProfileViewModel(
            userId: "user-other",
            userRepository: mockUserRepository,
            logRepository: mockLogRepository,
            savedContentRepository: mockSavedContentRepository
        )

        // When
        sut.loadProfile()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertNotNil(sut.profile)
        XCTAssertEqual(sut.profile?.username, "otheruser")
    }

    func testLoadProfile_failure_setsErrorState() async {
        // Given
        mockUserRepository.getUserProfileResult = .failure(.notFound)
        sut = ProfileViewModel(
            userId: "user-invalid",
            userRepository: mockUserRepository,
            logRepository: mockLogRepository,
            savedContentRepository: mockSavedContentRepository
        )

        // When
        sut.loadProfile()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        if case .error = sut.state {
            // Success
        } else {
            XCTFail("Expected error state")
        }
    }

    // MARK: - Tab Selection Tests

    func testSelectedTab_defaultIsRecipes() {
        // Given
        sut = ProfileViewModel(
            userId: nil,
            userRepository: mockUserRepository,
            logRepository: mockLogRepository,
            savedContentRepository: mockSavedContentRepository
        )

        // Then
        XCTAssertEqual(sut.selectedTab, .recipes)
    }

    func testSelectedTab_changingToLogs_updatesTab() async {
        // Given
        mockUserRepository.getMyProfileResult = .success(createMockMyProfile())
        sut = ProfileViewModel(
            userId: nil,
            userRepository: mockUserRepository,
            logRepository: mockLogRepository,
            savedContentRepository: mockSavedContentRepository
        )

        // When
        sut.selectedTab = .logs
        sut.loadContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.selectedTab, .logs)
    }

    func testSelectedTab_savedTab_availableForOwnProfile() {
        // Given
        sut = ProfileViewModel(
            userId: nil,
            userRepository: mockUserRepository,
            logRepository: mockLogRepository,
            savedContentRepository: mockSavedContentRepository
        )

        // When
        sut.selectedTab = .saved

        // Then - should be allowed for own profile
        XCTAssertEqual(sut.selectedTab, .saved)
    }

    // MARK: - Saved Content Tests

    func testSavedCount_returnsMyProfileSavedCount() async {
        // Given
        let myProfile = createMockMyProfile(savedCount: 42)
        mockUserRepository.getMyProfileResult = .success(myProfile)
        sut = ProfileViewModel(
            userId: nil,
            userRepository: mockUserRepository,
            logRepository: mockLogRepository,
            savedContentRepository: mockSavedContentRepository
        )

        // When
        sut.loadProfile()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.savedCount, 42)
    }

    // MARK: - Visibility Filter Tests

    func testVisibilityFilter_defaultIsAll() {
        // Given
        sut = ProfileViewModel(
            userId: nil,
            userRepository: mockUserRepository,
            logRepository: mockLogRepository,
            savedContentRepository: mockSavedContentRepository
        )

        // Then
        XCTAssertEqual(sut.visibilityFilter, .all)
    }

    func testVisibilityFilter_canBeChanged() {
        // Given
        sut = ProfileViewModel(
            userId: nil,
            userRepository: mockUserRepository,
            logRepository: mockLogRepository,
            savedContentRepository: mockSavedContentRepository
        )

        // When
        sut.visibilityFilter = .publicOnly

        // Then
        XCTAssertEqual(sut.visibilityFilter, .publicOnly)
    }

    // MARK: - Block User Tests

    func testBlockUser_success_updatesState() async {
        // Given
        let profile = createMockUserProfile()
        mockUserRepository.getUserProfileResult = .success(profile)
        sut = ProfileViewModel(
            userId: "user-other",
            userRepository: mockUserRepository,
            logRepository: mockLogRepository,
            savedContentRepository: mockSavedContentRepository
        )
        sut.loadProfile()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        await sut.blockUser()

        // Then
        XCTAssertTrue(sut.profile?.isBlocked ?? false)
    }

    // MARK: - Helpers

    private func createMockMyProfile(savedCount: Int = 10) -> MyProfile {
        MyProfile(
            user: UserInfo(
                id: "user-me",
                username: "testuser",
                role: "USER",
                profileImageUrl: nil,
                gender: nil,
                locale: "en",
                defaultCookingStyle: nil,
                measurementPreference: "METRIC",
                followerCount: 100,
                followingCount: 50,
                recipeCount: 15,
                logCount: 89,
                level: 12,
                levelName: "Home Cook",
                totalXp: 2450,
                xpForCurrentLevel: 450,
                xpForNextLevel: 1000,
                levelProgress: 0.45,
                bio: "Test bio",
                youtubeUrl: nil,
                instagramHandle: nil
            ),
            recipeCount: 15,
            logCount: 89,
            savedCount: savedCount
        )
    }

    private func createMockUserProfile(
        isFollowing: Bool = false,
        followerCount: Int = 100,
        recipeCount: Int = 10,
        logCount: Int = 20
    ) -> UserProfile {
        UserProfile(
            id: "user-other",
            username: "otheruser",
            displayName: "Other User",
            avatarUrl: nil,
            bio: "Other bio",
            level: 24,
            levelName: "skilledCook",
            recipeCount: recipeCount,
            logCount: logCount,
            followerCount: followerCount,
            followingCount: 150,
            youtubeUrl: nil,
            instagramHandle: nil,
            isFollowing: isFollowing,
            isFollowedBy: false,
            isBlocked: false,
            createdAt: Date()
        )
    }
}
