import XCTest
@testable import Cookstemma

final class UserRepositoryTests: XCTestCase {

    var sut: UserRepository!
    var mockAPIClient: MockAPIClient!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        sut = UserRepository(apiClient: mockAPIClient)
    }

    override func tearDown() {
        sut = nil
        mockAPIClient = nil
        super.tearDown()
    }

    // MARK: - getMyProfile Tests

    func testGetMyProfile_success_returnsProfile() async {
        // Given
        let expectedProfile = createMockMyProfile()
        mockAPIClient.mockResponse = expectedProfile

        // When
        let result = await sut.getMyProfile()

        // Then
        switch result {
        case .success(let profile):
            XCTAssertEqual(profile.id, "user-me")
            XCTAssertEqual(profile.username, "myuser")
            XCTAssertEqual(profile.level, 12)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetMyProfile_unauthorized_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.unauthorized

        // When
        let result = await sut.getMyProfile()

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .unauthorized)
        }
    }

    // MARK: - getUserProfile Tests

    func testGetUserProfile_success_returnsProfile() async {
        // Given
        let expectedProfile = createMockUserProfile()
        mockAPIClient.mockResponse = expectedProfile

        // When
        let result = await sut.getUserProfile(id: "user-other")

        // Then
        switch result {
        case .success(let profile):
            XCTAssertEqual(profile.id, "user-other")
            XCTAssertEqual(profile.username, "otheruser")
            XCTAssertFalse(profile.isFollowing)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetUserProfile_notFound_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.notFound

        // When
        let result = await sut.getUserProfile(id: "non-existent")

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .notFound)
        }
    }

    // MARK: - updateProfile Tests

    func testUpdateProfile_success_returnsUpdatedProfile() async {
        // Given
        let expectedProfile = createMockMyProfile()
        mockAPIClient.mockResponse = expectedProfile

        let request = UpdateProfileRequest(
            username: "newusername",
            bio: "Updated bio",
            avatarImageId: nil,
            youtubeUrl: nil,
            instagramHandle: nil,
            measurementPreference: nil
        )

        // When
        let result = await sut.updateProfile(request)

        // Then
        switch result {
        case .success(let profile):
            XCTAssertEqual(profile.id, "user-me")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - getUserRecipes Tests

    func testGetUserRecipes_success_returnsPaginatedRecipes() async {
        // Given
        let recipes = [createMockRecipeSummary(), createMockRecipeSummary()]
        let expectedResponse = PaginatedResponse(
            content: recipes,
            nextCursor: "cursor",
            hasNext: true
        )
        mockAPIClient.mockResponse = expectedResponse

        // When
        let result = await sut.getUserRecipes(userId: "user-123", cursor: nil)

        // Then
        switch result {
        case .success(let response):
            XCTAssertEqual(response.content.count, 2)
            XCTAssertTrue(response.hasMore)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - follow Tests

    func testFollow_success_returnsVoid() async {
        // Given
        mockAPIClient.mockResponse = EmptyResponse()

        // When
        let result = await sut.follow(userId: "user-to-follow")

        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testFollow_alreadyFollowing_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.serverError(409, "Already following")

        // When
        let result = await sut.follow(userId: "user-123")

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .serverError("Already following"))
        }
    }

    // MARK: - unfollow Tests

    func testUnfollow_success_returnsVoid() async {
        // Given
        mockAPIClient.mockResponse = EmptyResponse()

        // When
        let result = await sut.unfollow(userId: "user-to-unfollow")

        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - getFollowers Tests

    func testGetFollowers_success_returnsPaginatedUsers() async {
        // Given
        let users = [createMockUserSummary(), createMockUserSummary()]
        let expectedResponse = PaginatedResponse(
            content: users,
            nextCursor: "next",
            hasNext: true
        )
        mockAPIClient.mockResponse = expectedResponse

        // When
        let result = await sut.getFollowers(userId: "user-123", cursor: nil)

        // Then
        switch result {
        case .success(let response):
            XCTAssertEqual(response.content.count, 2)
            XCTAssertTrue(response.hasMore)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - getFollowing Tests

    func testGetFollowing_success_returnsPaginatedUsers() async {
        // Given
        let users = [createMockUserSummary()]
        let expectedResponse = PaginatedResponse(
            content: users,
            nextCursor: nil,
            hasNext: false
        )
        mockAPIClient.mockResponse = expectedResponse

        // When
        let result = await sut.getFollowing(userId: "user-123", cursor: nil)

        // Then
        switch result {
        case .success(let response):
            XCTAssertEqual(response.content.count, 1)
            XCTAssertFalse(response.hasMore)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - blockUser Tests

    func testBlockUser_success_returnsVoid() async {
        // Given
        mockAPIClient.mockResponse = EmptyResponse()

        // When
        let result = await sut.blockUser(userId: "user-to-block")

        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - unblockUser Tests

    func testUnblockUser_success_returnsVoid() async {
        // Given
        mockAPIClient.mockResponse = EmptyResponse()

        // When
        let result = await sut.unblockUser(userId: "user-to-unblock")

        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - reportUser Tests

    func testReportUser_success_returnsVoid() async {
        // Given
        mockAPIClient.mockResponse = EmptyResponse()

        // When
        let result = await sut.reportUser(userId: "user-to-report", reason: .harassment)

        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testReportUser_allReasons() async {
        // Given
        mockAPIClient.mockResponse = EmptyResponse()
        let reasons: [ReportReason] = [.spam, .harassment, .inappropriateContent, .impersonation, .other]

        for reason in reasons {
            // When
            let result = await sut.reportUser(userId: "user-123", reason: reason)

            // Then
            switch result {
            case .success:
                break // Expected
            case .failure(let error):
                XCTFail("Expected success for \(reason), got error: \(error)")
            }
        }
    }

    // MARK: - Helpers

    private func createMockMyProfile() -> MyProfile {
        let userInfo = UserInfo(
            id: "user-me",
            username: "myuser",
            role: "USER",
            profileImageUrl: nil,
            gender: nil,
            locale: "en",
            defaultCookingStyle: nil,
            measurementPreference: "METRIC",
            followerCount: 1200,
            followingCount: 350,
            recipeCount: 15,
            logCount: 89,
            level: 12,
            levelName: "homeCook",
            totalXp: 2450,
            xpForCurrentLevel: 450,
            xpForNextLevel: 1000,
            levelProgress: 0.45,
            bio: "My bio",
            youtubeUrl: nil,
            instagramHandle: nil
        )
        return MyProfile(
            user: userInfo,
            recipeCount: 15,
            logCount: 89,
            savedCount: 5
        )
    }

    private func createMockUserProfile() -> UserProfile {
        UserProfile(
            id: "user-other",
            username: "otheruser",
            displayName: "Other User",
            avatarUrl: nil,
            bio: "Other bio",
            level: 24,
            levelName: "skilledCook",
            recipeCount: 45,
            logCount: 203,
            followerCount: 5200,
            followingCount: 150,
            youtubeUrl: nil,
            instagramHandle: nil,
            isFollowing: false,
            isFollowedBy: false,
            isBlocked: false,
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

    private func createMockRecipeSummary() -> RecipeSummary {
        RecipeSummary(
            id: "recipe-123",
            title: "Test Recipe",
            description: nil,
            foodName: "Test Food",
            cookingStyle: "US",
            userName: "testuser",
            thumbnail: nil,
            variantCount: 1,
            logCount: 50,
            servings: 2,
            cookingTimeRange: "UNDER_15",
            hashtags: [],
            isPrivate: false,
            isSaved: false
        )
    }
}

// MARK: - Empty Response

private struct EmptyResponse: Decodable {}
