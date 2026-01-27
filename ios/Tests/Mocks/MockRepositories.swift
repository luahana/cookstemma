import Foundation
@testable import Cookstemma

// MARK: - Mock Recipe Repository

final class MockRecipeRepository: RecipeRepositoryProtocol {
    var getRecipesResult: RepositoryResult<PaginatedResponse<RecipeSummary>> = .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    var getRecipeCalled = false
    var getRecipeResult: RepositoryResult<RecipeDetail>?
    var saveRecipeCalled = false
    var unsaveRecipeCalled = false

    func getRecipes(cursor: String?, filters: RecipeFilters?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>> {
        return getRecipesResult
    }

    func getRecipe(id: String) async -> RepositoryResult<RecipeDetail> {
        getRecipeCalled = true
        return getRecipeResult ?? .failure(.notFound)
    }

    func getRecipeLogs(recipeId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeLogItem>> {
        return .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    }

    func saveRecipe(id: String) async -> RepositoryResult<Void> {
        saveRecipeCalled = true
        return .success(())
    }

    func unsaveRecipe(id: String) async -> RepositoryResult<Void> {
        unsaveRecipeCalled = true
        return .success(())
    }

    func isRecipeSaved(id: String) async -> RepositoryResult<Bool> {
        return .success(false)
    }

    func recordRecipeView(id: String) async {
        // No-op for mock
    }

    func getRecentlyViewedRecipes(limit: Int) async -> RepositoryResult<[RecipeSummary]> {
        return .success([])
    }
}

// MARK: - Mock Cooking Log Repository

final class MockCookingLogRepository: CookingLogRepositoryProtocol {
    var getHomeFeedResult: RepositoryResult<HomeFeedResponse> = .success(HomeFeedResponse(recentActivity: [], recentRecipes: [], trendingTrees: nil))
    var getFeedResult: RepositoryResult<PaginatedResponse<FeedLogItem>> = .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    var getLogResult: RepositoryResult<CookingLogDetail>?
    var createLogResult: RepositoryResult<CookingLogDetail>?
    var likeLogCalled = false
    var unlikeLogCalled = false
    var saveLogCalled = false
    var unsaveLogCalled = false

    func getHomeFeed() async -> RepositoryResult<HomeFeedResponse> {
        return getHomeFeedResult
    }

    func getFeed(cursor: String?, size: Int) async -> RepositoryResult<PaginatedResponse<FeedLogItem>> {
        return getFeedResult
    }

    func getLog(id: String) async -> RepositoryResult<CookingLogDetail> {
        return getLogResult ?? .failure(.notFound)
    }

    func getUserLogs(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<CookingLogSummary>> {
        return .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    }

    func createLog(_ request: CreateLogRequest) async -> RepositoryResult<CookingLogDetail> {
        return createLogResult ?? .failure(.unknown)
    }

    func updateLog(id: String, _ request: UpdateLogRequest) async -> RepositoryResult<CookingLogDetail> {
        return .failure(.notFound)
    }

    func deleteLog(id: String) async -> RepositoryResult<Void> {
        return .success(())
    }

    func likeLog(id: String) async -> RepositoryResult<Void> {
        likeLogCalled = true
        return .success(())
    }

    func unlikeLog(id: String) async -> RepositoryResult<Void> {
        unlikeLogCalled = true
        return .success(())
    }

    func saveLog(id: String) async -> RepositoryResult<Void> {
        saveLogCalled = true
        return .success(())
    }

    func unsaveLog(id: String) async -> RepositoryResult<Void> {
        unsaveLogCalled = true
        return .success(())
    }
}

// MARK: - Mock User Repository

final class MockUserRepository: UserRepositoryProtocol {
    var getMyProfileResult: RepositoryResult<MyProfile>?
    var getUserProfileResult: RepositoryResult<UserProfile>?
    var updateProfileResult: RepositoryResult<MyProfile>?
    var checkUsernameAvailabilityResult: RepositoryResult<Bool> = .success(true)
    var followCalled = false
    var unfollowCalled = false
    var blockCalled = false
    var updateProfileCalled = false
    var checkUsernameAvailabilityCalled = false
    var lastCheckedUsername: String?
    var lastUpdateProfileRequest: UpdateProfileRequest?

    func getMyProfile() async -> RepositoryResult<MyProfile> {
        return getMyProfileResult ?? .failure(.notFound)
    }

    func getUserProfile(id: String) async -> RepositoryResult<UserProfile> {
        return getUserProfileResult ?? .failure(.notFound)
    }

    func updateProfile(_ request: UpdateProfileRequest) async -> RepositoryResult<MyProfile> {
        updateProfileCalled = true
        lastUpdateProfileRequest = request
        return updateProfileResult ?? getMyProfileResult ?? .failure(.notFound)
    }

    func checkUsernameAvailability(_ username: String) async -> RepositoryResult<Bool> {
        checkUsernameAvailabilityCalled = true
        lastCheckedUsername = username
        return checkUsernameAvailabilityResult
    }

    func getUserRecipes(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>> {
        return .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    }

    func follow(userId: String) async -> RepositoryResult<Void> {
        followCalled = true
        return .success(())
    }

    func unfollow(userId: String) async -> RepositoryResult<Void> {
        unfollowCalled = true
        return .success(())
    }

    func getFollowers(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<UserSummary>> {
        return .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    }

    func getFollowing(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<UserSummary>> {
        return .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    }

    func blockUser(userId: String) async -> RepositoryResult<Void> {
        blockCalled = true
        return .success(())
    }

    func unblockUser(userId: String) async -> RepositoryResult<Void> {
        return .success(())
    }

    func reportUser(userId: String, reason: ReportReason) async -> RepositoryResult<Void> {
        return .success(())
    }
}

// MARK: - Mock Comment Repository

final class MockCommentRepository: CommentRepositoryProtocol {
    var getCommentsResult: RepositoryResult<PaginatedResponse<Comment>> = .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    var createCommentResult: RepositoryResult<Comment>?
    var updateCommentResult: RepositoryResult<Comment>?
    var deleteCommentResult: RepositoryResult<Void> = .success(())
    var likeCommentResult: RepositoryResult<Void> = .success(())
    var unlikeCommentResult: RepositoryResult<Void> = .success(())
    var likeCommentCalled = false
    var unlikeCommentCalled = false

    func getComments(logId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<Comment>> {
        return getCommentsResult
    }

    func createComment(logId: String, content: String, parentId: String?) async -> RepositoryResult<Comment> {
        return createCommentResult ?? .failure(.unknown)
    }

    func updateComment(id: String, content: String) async -> RepositoryResult<Comment> {
        return updateCommentResult ?? .failure(.notFound)
    }

    func deleteComment(id: String) async -> RepositoryResult<Void> {
        return deleteCommentResult
    }

    func likeComment(id: String) async -> RepositoryResult<Void> {
        likeCommentCalled = true
        return likeCommentResult
    }

    func unlikeComment(id: String) async -> RepositoryResult<Void> {
        unlikeCommentCalled = true
        return unlikeCommentResult
    }
}

// MARK: - Mock Search Repository

final class MockSearchRepository: SearchRepositoryProtocol {
    var searchResult: RepositoryResult<SearchResponse> = .success(SearchResponse(recipes: [], logs: [], users: [], hashtags: []))
    var trendingHashtagsResult: RepositoryResult<[HashtagCount]> = .success([])

    func search(query: String, type: SearchType?, cursor: String?) async -> RepositoryResult<SearchResponse> {
        return searchResult
    }

    func searchRecipes(query: String, filters: RecipeFilters?, cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>> {
        return .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    }

    func searchLogs(query: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<CookingLogSummary>> {
        return .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    }

    func searchUsers(query: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<UserSummary>> {
        return .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    }

    func getTrendingHashtags() async -> RepositoryResult<[HashtagCount]> {
        return trendingHashtagsResult
    }

    func getHashtagContent(hashtag: String, type: SearchType?, cursor: String?) async -> RepositoryResult<SearchResponse> {
        return searchResult
    }
}

// MARK: - Mock Saved Content Repository

final class MockSavedContentRepository: SavedContentRepositoryProtocol {
    var getSavedRecipesResult: RepositoryResult<PaginatedResponse<RecipeSummary>> = .success(
        PaginatedResponse(content: [], nextCursor: nil, hasNext: false)
    )
    var getSavedLogsResult: RepositoryResult<PaginatedResponse<CookingLogSummary>> = .success(
        PaginatedResponse(content: [], nextCursor: nil, hasNext: false)
    )

    func getSavedRecipes(cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>> {
        return getSavedRecipesResult
    }

    func getSavedLogs(cursor: String?) async -> RepositoryResult<PaginatedResponse<CookingLogSummary>> {
        return getSavedLogsResult
    }
}

// MARK: - Mock Notification Repository

final class MockNotificationRepository: NotificationRepositoryProtocol {
    var getNotificationsResult: RepositoryResult<PaginatedResponse<AppNotification>> = .success(PaginatedResponse(content: [], nextCursor: nil, hasNext: false))
    var unreadCountResult: RepositoryResult<Int> = .success(0)
    var markAsReadCalled = false
    var markAllAsReadCalled = false

    func getNotifications(cursor: String?) async -> RepositoryResult<PaginatedResponse<AppNotification>> {
        return getNotificationsResult
    }

    func getUnreadCount() async -> RepositoryResult<Int> {
        return unreadCountResult
    }

    func markAsRead(id: String) async -> RepositoryResult<Void> {
        markAsReadCalled = true
        return .success(())
    }

    func markAllAsRead() async -> RepositoryResult<Void> {
        markAllAsReadCalled = true
        return .success(())
    }

    func registerFCMToken(_ token: String) async -> RepositoryResult<Void> {
        return .success(())
    }

    func unregisterFCMToken(_ token: String) async -> RepositoryResult<Void> {
        return .success(())
    }
}
