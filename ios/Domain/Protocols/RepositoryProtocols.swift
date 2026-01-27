import Foundation

// MARK: - Pagination

struct PaginatedResponse<T: Codable>: Codable {
    let content: [T]
    let nextCursor: String?
    let hasNext: Bool

    var hasMore: Bool { hasNext }
}

// MARK: - Repository Error

enum RepositoryError: Error, Equatable {
    case networkError(String)
    case unauthorized
    case notFound
    case serverError(String)
    case decodingError(String)
    case unknown

    var localizedDescription: String {
        switch self {
        case .networkError(let msg): return "Network error: \(msg)"
        case .unauthorized: return "Please log in again"
        case .notFound: return "Not found"
        case .serverError(let msg): return "Server error: \(msg)"
        case .decodingError(let msg): return "Data error: \(msg)"
        case .unknown: return "An unknown error occurred"
        }
    }
}

typealias RepositoryResult<T> = Result<T, RepositoryError>

// MARK: - Recipe Repository

protocol RecipeRepositoryProtocol {
    func getRecipes(cursor: String?, filters: RecipeFilters?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>>
    func getRecipe(id: String) async -> RepositoryResult<RecipeDetail>
    func getRecipeLogs(recipeId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<CookingLogSummary>>
    func saveRecipe(id: String) async -> RepositoryResult<Void>
    func unsaveRecipe(id: String) async -> RepositoryResult<Void>
    func isRecipeSaved(id: String) async -> RepositoryResult<Bool>
    func recordRecipeView(id: String) async
    func getRecentlyViewedRecipes(limit: Int) async -> RepositoryResult<[RecipeSummary]>
}

// MARK: - Cooking Log Repository

protocol CookingLogRepositoryProtocol {
    func getHomeFeed() async -> RepositoryResult<HomeFeedResponse>
    func getFeed(cursor: String?, size: Int) async -> RepositoryResult<PaginatedResponse<FeedLogItem>>
    func getLog(id: String) async -> RepositoryResult<CookingLogDetail>
    func getUserLogs(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<CookingLogSummary>>
    func createLog(_ request: CreateLogRequest) async -> RepositoryResult<CookingLogDetail>
    func updateLog(id: String, _ request: UpdateLogRequest) async -> RepositoryResult<CookingLogDetail>
    func deleteLog(id: String) async -> RepositoryResult<Void>
    func likeLog(id: String) async -> RepositoryResult<Void>
    func unlikeLog(id: String) async -> RepositoryResult<Void>
    func saveLog(id: String) async -> RepositoryResult<Void>
    func unsaveLog(id: String) async -> RepositoryResult<Void>
}

// MARK: - User Repository

protocol UserRepositoryProtocol {
    func getMyProfile() async -> RepositoryResult<MyProfile>
    func getUserProfile(id: String) async -> RepositoryResult<UserProfile>
    func updateProfile(_ request: UpdateProfileRequest) async -> RepositoryResult<MyProfile>
    func getUserRecipes(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>>
    func follow(userId: String) async -> RepositoryResult<Void>
    func unfollow(userId: String) async -> RepositoryResult<Void>
    func getFollowers(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<UserSummary>>
    func getFollowing(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<UserSummary>>
    func blockUser(userId: String) async -> RepositoryResult<Void>
    func unblockUser(userId: String) async -> RepositoryResult<Void>
    func reportUser(userId: String, reason: ReportReason) async -> RepositoryResult<Void>
}

// MARK: - Comment Repository

protocol CommentRepositoryProtocol {
    func getComments(logId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<Comment>>
    func createComment(logId: String, content: String, parentId: String?) async -> RepositoryResult<Comment>
    func updateComment(id: String, content: String) async -> RepositoryResult<Comment>
    func deleteComment(id: String) async -> RepositoryResult<Void>
    func likeComment(id: String) async -> RepositoryResult<Void>
    func unlikeComment(id: String) async -> RepositoryResult<Void>
}

// MARK: - Search Repository

protocol SearchRepositoryProtocol {
    func search(query: String, type: SearchType?, cursor: String?) async -> RepositoryResult<SearchResponse>
    func searchRecipes(query: String, filters: RecipeFilters?, cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>>
    func searchLogs(query: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<CookingLogSummary>>
    func searchUsers(query: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<UserSummary>>
    func getTrendingHashtags() async -> RepositoryResult<[HashtagCount]>
    func getHashtagContent(hashtag: String, type: SearchType?, cursor: String?) async -> RepositoryResult<SearchResponse>
}

// MARK: - Notification Repository

protocol NotificationRepositoryProtocol {
    func getNotifications(cursor: String?) async -> RepositoryResult<PaginatedResponse<AppNotification>>
    func getUnreadCount() async -> RepositoryResult<Int>
    func markAsRead(id: String) async -> RepositoryResult<Void>
    func markAllAsRead() async -> RepositoryResult<Void>
    func registerFCMToken(_ token: String) async -> RepositoryResult<Void>
    func unregisterFCMToken(_ token: String) async -> RepositoryResult<Void>
}

// MARK: - Saved Content Repository

protocol SavedContentRepositoryProtocol {
    func getSavedRecipes(cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>>
    func getSavedLogs(cursor: String?) async -> RepositoryResult<PaginatedResponse<CookingLogSummary>>
}
