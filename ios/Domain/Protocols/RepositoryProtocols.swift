import Foundation

// MARK: - Pagination

/// Flexible pagination response that handles both cursor-based and Spring Page formats
struct PaginatedResponse<T: Codable>: Codable {
    let content: [T]
    let nextCursor: String?
    let hasNext: Bool

    var hasMore: Bool { hasNext }

    enum CodingKeys: String, CodingKey {
        case content, nextCursor, hasNext
        // Spring Page format keys
        case last, number
    }

    init(content: [T], nextCursor: String?, hasNext: Bool) {
        self.content = content
        self.nextCursor = nextCursor
        self.hasNext = hasNext
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode([T].self, forKey: .content)

        // Try cursor-based format first
        if let hasNext = try? container.decode(Bool.self, forKey: .hasNext) {
            self.hasNext = hasNext
            self.nextCursor = try container.decodeIfPresent(String.self, forKey: .nextCursor)
        }
        // Fall back to Spring Page format (has `last` instead of `hasNext`)
        else if let last = try? container.decode(Bool.self, forKey: .last) {
            self.hasNext = !last
            // For Spring Page, use page number as cursor
            if let pageNumber = try? container.decode(Int.self, forKey: .number), !last {
                self.nextCursor = String(pageNumber + 1)
            } else {
                self.nextCursor = nil
            }
        } else {
            self.hasNext = false
            self.nextCursor = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(nextCursor, forKey: .nextCursor)
        try container.encode(hasNext, forKey: .hasNext)
    }
}

/// Spring Slice response format (offset-based pagination)
struct SliceResponse<T: Codable>: Codable {
    let content: [T]
    let last: Bool
    let first: Bool
    let empty: Bool
    let numberOfElements: Int
    let size: Int
    let number: Int

    var hasMore: Bool { !last }
    var nextPage: Int? { last ? nil : number + 1 }

    /// Convert to PaginatedResponse for compatibility
    func toPaginatedResponse() -> PaginatedResponse<T> {
        PaginatedResponse(
            content: content,
            nextCursor: nextPage.map { String($0) },
            hasNext: hasMore
        )
    }
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
    func getRecipeLogs(recipeId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeLogItem>>
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
    func getUserLogs(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<FeedLogItem>>
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
    func updateProfile(_ request: UpdateProfileRequest) async -> RepositoryResult<Void>
    func checkUsernameAvailability(_ username: String) async -> RepositoryResult<Bool>
    func getUserRecipes(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>>
    func follow(userId: String) async -> RepositoryResult<Void>
    func unfollow(userId: String) async -> RepositoryResult<Void>
    func getFollowers(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<UserSummary>>
    func getFollowing(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<UserSummary>>
    func blockUser(userId: String) async -> RepositoryResult<Void>
    func unblockUser(userId: String) async -> RepositoryResult<Void>
    func getBlockedUsers(page: Int) async -> RepositoryResult<BlockedUsersResponse>
    func reportUser(userId: String, reason: ReportReason) async -> RepositoryResult<Void>
    func deleteAccount() async -> RepositoryResult<Void>
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
    func search(query: String, type: SearchType?, cursor: String?, size: Int) async -> RepositoryResult<UnifiedSearchResponse>
    func searchRecipes(query: String, filters: RecipeFilters?, cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>>
    func searchLogs(query: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<CookingLogSummary>>
    func searchUsers(query: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<UserSummary>>
    func getTrendingHashtags() async -> RepositoryResult<[HashtagCount]>
    func getHashtagContent(hashtag: String, type: SearchType?, cursor: String?) async -> RepositoryResult<HashtagContentResponse>
}

// MARK: - Notification Repository

protocol NotificationRepositoryProtocol {
    func getNotifications(cursor: String?) async -> RepositoryResult<PaginatedResponse<AppNotification>>
    func getUnreadCount() async -> RepositoryResult<Int>
    func markAsRead(id: String) async -> RepositoryResult<Void>
    func markAllAsRead() async -> RepositoryResult<Void>
    func deleteNotification(id: String) async -> RepositoryResult<Void>
    func deleteAllNotifications() async -> RepositoryResult<Void>
    func registerFCMToken(_ token: String) async -> RepositoryResult<Void>
    func unregisterFCMToken(_ token: String) async -> RepositoryResult<Void>
}

// MARK: - Saved Content Repository

protocol SavedContentRepositoryProtocol {
    func getSavedRecipes(cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>>
    func getSavedLogs(cursor: String?) async -> RepositoryResult<PaginatedResponse<FeedLogItem>>
}
