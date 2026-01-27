import XCTest
@testable import Cookstemma

@MainActor
final class ProfileViewModelTests: XCTestCase {

    var sut: ProfileViewModel!
    var mockUserRepository: MockUserRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockUserRepository = MockUserRepository()
    }

    override func tearDown() async throws {
        sut = nil
        mockUserRepository = nil
        try await super.tearDown()
    }

    // MARK: - Load Own Profile Tests

    func testLoadProfile_withNilUserId_loadsOwnProfile() async {
        // Given
        let myProfile = createMockMyProfile()
        mockUserRepository.getMyProfileResult = .success(myProfile)
        sut = ProfileViewModel(userId: nil, userRepository: mockUserRepository)

        // When
        await sut.loadProfile()

        // Then
        XCTAssertEqual(sut.profile?.id, "user-me")
        XCTAssertEqual(sut.profile?.username, "myuser")
        XCTAssertTrue(sut.isOwnProfile)
    }

    func testLoadProfile_ownProfile_showsEditButton() async {
        // Given
        mockUserRepository.getMyProfileResult = .success(createMockMyProfile())
        sut = ProfileViewModel(userId: nil, userRepository: mockUserRepository)

        // When
        await sut.loadProfile()

        // Then
        XCTAssertTrue(sut.isOwnProfile)
    }

    // MARK: - Load Other User Profile Tests

    func testLoadProfile_withUserId_loadsUserProfile() async {
        // Given
        let userProfile = createMockUserProfile()
        mockUserRepository.getUserProfileResult = .success(userProfile)
        sut = ProfileViewModel(userId: "user-other", userRepository: mockUserRepository)

        // When
        await sut.loadProfile()

        // Then
        XCTAssertEqual(sut.profile?.id, "user-other")
        XCTAssertFalse(sut.isOwnProfile)
    }

    func testLoadProfile_failure_setsErrorState() async {
        // Given
        mockUserRepository.getUserProfileResult = .failure(.notFound)
        sut = ProfileViewModel(userId: "user-invalid", userRepository: mockUserRepository)

        // When
        await sut.loadProfile()

        // Then
        XCTAssertNotNil(sut.error)
    }

    // MARK: - Follow/Unfollow Tests

    func testToggleFollow_notFollowing_follows() async {
        // Given
        let profile = createMockUserProfile(isFollowing: false)
        mockUserRepository.getUserProfileResult = .success(profile)
        mockUserRepository.followResult = .success(())
        sut = ProfileViewModel(userId: "user-other", userRepository: mockUserRepository)
        await sut.loadProfile()

        XCTAssertFalse(sut.isFollowing)

        // When
        await sut.toggleFollow()

        // Then
        XCTAssertTrue(sut.isFollowing)
    }

    func testToggleFollow_following_unfollows() async {
        // Given
        let profile = createMockUserProfile(isFollowing: true)
        mockUserRepository.getUserProfileResult = .success(profile)
        mockUserRepository.unfollowResult = .success(())
        sut = ProfileViewModel(userId: "user-other", userRepository: mockUserRepository)
        await sut.loadProfile()

        XCTAssertTrue(sut.isFollowing)

        // When
        await sut.toggleFollow()

        // Then
        XCTAssertFalse(sut.isFollowing)
    }

    func testToggleFollow_optimisticallyUpdatesFollowerCount() async {
        // Given
        let profile = createMockUserProfile(isFollowing: false, followerCount: 100)
        mockUserRepository.getUserProfileResult = .success(profile)
        mockUserRepository.followResult = .success(())
        sut = ProfileViewModel(userId: "user-other", userRepository: mockUserRepository)
        await sut.loadProfile()

        // When
        await sut.toggleFollow()

        // Then
        XCTAssertEqual(sut.followerCount, 101)
    }

    func testToggleFollow_failure_revertsState() async {
        // Given
        let profile = createMockUserProfile(isFollowing: false, followerCount: 100)
        mockUserRepository.getUserProfileResult = .success(profile)
        mockUserRepository.followResult = .failure(.networkError("Failed"))
        sut = ProfileViewModel(userId: "user-other", userRepository: mockUserRepository)
        await sut.loadProfile()

        // When
        await sut.toggleFollow()

        // Then - should revert
        XCTAssertFalse(sut.isFollowing)
        XCTAssertEqual(sut.followerCount, 100)
    }

    // MARK: - Tab Selection Tests

    func testSelectTab_recipes_loadsRecipes() async {
        // Given
        mockUserRepository.getMyProfileResult = .success(createMockMyProfile())
        mockUserRepository.getUserRecipesResult = .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
        sut = ProfileViewModel(userId: nil, userRepository: mockUserRepository)
        await sut.loadProfile()

        // When
        await sut.selectTab(.recipes)

        // Then
        XCTAssertEqual(sut.selectedTab, .recipes)
    }

    func testSelectTab_logs_loadsLogs() async {
        // Given
        mockUserRepository.getMyProfileResult = .success(createMockMyProfile())
        mockUserRepository.getUserLogsResult = .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
        sut = ProfileViewModel(userId: nil, userRepository: mockUserRepository)
        await sut.loadProfile()

        // When
        await sut.selectTab(.logs)

        // Then
        XCTAssertEqual(sut.selectedTab, .logs)
    }

    // MARK: - Block User Tests

    func testBlockUser_success_updatesState() async {
        // Given
        let profile = createMockUserProfile()
        mockUserRepository.getUserProfileResult = .success(profile)
        mockUserRepository.blockUserResult = .success(())
        sut = ProfileViewModel(userId: "user-other", userRepository: mockUserRepository)
        await sut.loadProfile()

        // When
        await sut.blockUser()

        // Then
        XCTAssertTrue(sut.isBlocked)
    }

    // MARK: - Stats Tests

    func testProfile_hasCorrectStats() async {
        // Given
        let profile = createMockUserProfile(recipeCount: 45, logCount: 203, followerCount: 5200)
        mockUserRepository.getUserProfileResult = .success(profile)
        sut = ProfileViewModel(userId: "user-other", userRepository: mockUserRepository)

        // When
        await sut.loadProfile()

        // Then
        XCTAssertEqual(sut.recipeCount, 45)
        XCTAssertEqual(sut.logCount, 203)
        XCTAssertEqual(sut.followerCount, 5200)
    }

    // MARK: - Helpers

    private func createMockMyProfile() -> MyProfile {
        MyProfile(
            id: "user-me",
            username: "myuser",
            displayName: "My User",
            email: "me@example.com",
            avatarUrl: nil,
            bio: "My bio",
            level: 12,
            xp: 2450,
            xpToNextLevel: 1000,
            recipeCount: 15,
            logCount: 89,
            followerCount: 1200,
            followingCount: 350,
            socialLinks: nil,
            measurementPreference: .metric,
            createdAt: Date()
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
            recipeCount: recipeCount,
            logCount: logCount,
            followerCount: followerCount,
            followingCount: 150,
            socialLinks: nil,
            isFollowing: isFollowing,
            isFollowedBy: false,
            isBlocked: false,
            createdAt: Date()
        )
    }
}

// MARK: - Mock User Repository

class MockUserRepository: UserRepositoryProtocol {
    var getMyProfileResult: RepositoryResult<MyProfile>?
    var getUserProfileResult: RepositoryResult<UserProfile>?
    var updateProfileResult: RepositoryResult<MyProfile>?
    var getUserRecipesResult: RepositoryResult<PaginatedResponse<RecipeSummary>> = .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    var getUserLogsResult: RepositoryResult<PaginatedResponse<CookingLogSummary>> = .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    var followResult: RepositoryResult<Void> = .success(())
    var unfollowResult: RepositoryResult<Void> = .success(())
    var getFollowersResult: RepositoryResult<PaginatedResponse<UserSummary>> = .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    var getFollowingResult: RepositoryResult<PaginatedResponse<UserSummary>> = .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    var blockUserResult: RepositoryResult<Void> = .success(())
    var unblockUserResult: RepositoryResult<Void> = .success(())
    var reportUserResult: RepositoryResult<Void> = .success(())

    func getMyProfile() async -> RepositoryResult<MyProfile> { getMyProfileResult ?? .failure(.unauthorized) }
    func getUserProfile(id: String) async -> RepositoryResult<UserProfile> { getUserProfileResult ?? .failure(.notFound) }
    func updateProfile(_ request: UpdateProfileRequest) async -> RepositoryResult<MyProfile> { updateProfileResult ?? .failure(.unknown) }
    func getUserRecipes(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>> { getUserRecipesResult }
    func getUserLogs(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<CookingLogSummary>> { getUserLogsResult }
    func follow(userId: String) async -> RepositoryResult<Void> { followResult }
    func unfollow(userId: String) async -> RepositoryResult<Void> { unfollowResult }
    func getFollowers(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<UserSummary>> { getFollowersResult }
    func getFollowing(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<UserSummary>> { getFollowingResult }
    func blockUser(userId: String) async -> RepositoryResult<Void> { blockUserResult }
    func unblockUser(userId: String) async -> RepositoryResult<Void> { unblockUserResult }
    func reportUser(userId: String, reason: ReportReason) async -> RepositoryResult<Void> { reportUserResult }
}
