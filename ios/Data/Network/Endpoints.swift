import Foundation

// MARK: - Auth Response

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let userPublicId: String
    let username: String
    let role: String
}

// MARK: - Auth Request (camelCase keys for backend)

struct SocialLoginRequest: Codable {
    let idToken: String
    let locale: String

    enum CodingKeys: String, CodingKey {
        case idToken
        case locale
    }
}

struct TokenReissueRequest: Codable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken
    }
}

// MARK: - Auth Endpoints

enum AuthEndpoint: APIEndpoint {
    case socialLogin(idToken: String, locale: String)
    case refreshToken(refreshToken: String)
    case logout

    var path: String {
        switch self {
        case .socialLogin: return "auth/social-login"
        case .refreshToken: return "auth/reissue"
        case .logout: return "auth/logout"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .socialLogin, .refreshToken: return .post
        case .logout: return .delete
        }
    }

    var body: Encodable? {
        switch self {
        case .socialLogin(let idToken, let locale):
            return SocialLoginRequest(idToken: idToken, locale: locale)
        case .refreshToken(let token):
            return TokenReissueRequest(refreshToken: token)
        case .logout:
            return nil
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .socialLogin, .refreshToken: return false
        case .logout: return true
        }
    }
}

// MARK: - Recipe Endpoints

enum RecipeEndpoint: APIEndpoint {
    case list(cursor: String?, filters: RecipeFilters?)
    case detail(id: String)
    case logs(recipeId: String, cursor: String?)
    case save(id: String)
    case unsave(id: String)

    var path: String {
        switch self {
        case .list: return "recipes"
        case .detail(let id): return "recipes/\(id)"
        case .logs(let id, _): return "log_posts/recipe/\(id)"
        case .save(let id), .unsave(let id): return "recipes/\(id)/save"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list, .detail, .logs: return .get
        case .save: return .post
        case .unsave: return .delete
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .list(let cursor, let filters):
            var items: [URLQueryItem] = []
            if let cursor = cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
            if let filters = filters {
                if let t = filters.cookingTimeRange { items.append(URLQueryItem(name: "cookingTime", value: t.rawValue)) }
                if let c = filters.category { items.append(URLQueryItem(name: "category", value: c)) }
                if let q = filters.searchQuery { items.append(URLQueryItem(name: "q", value: q)) }
                if let minS = filters.minServings { items.append(URLQueryItem(name: "minServings", value: String(minS))) }
                if let maxS = filters.maxServings { items.append(URLQueryItem(name: "maxServings", value: String(maxS))) }
                if let style = filters.cookingStyle { items.append(URLQueryItem(name: "locale", value: style)) }
            }
            return items.isEmpty ? nil : items
        case .logs(_, let cursor):
            // Backend uses page-based pagination (Spring Slice)
            var items = [URLQueryItem(name: "size", value: "20")]
            if let page = cursor { items.append(URLQueryItem(name: "page", value: page)) }
            return items
        default: return nil
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .list, .detail, .logs: return false
        case .save, .unsave: return true
        }
    }
}

// MARK: - Log Endpoints

enum LogEndpoint: APIEndpoint {
    case home
    case feed(cursor: String?, size: Int)
    case detail(id: String)
    case userLogs(userId: String, cursor: String?)
    case create(CreateLogRequest)
    case update(id: String, UpdateLogRequest)
    case delete(id: String)
    case like(id: String)
    case unlike(id: String)
    case save(id: String)
    case unsave(id: String)

    var path: String {
        switch self {
        case .home: return "home"
        case .feed: return "log_posts"
        case .detail(let id): return "log_posts/\(id)"
        case .userLogs(let userId, _): return "users/\(userId)/logs"
        case .create: return "log_posts"
        case .update(let id, _), .delete(let id): return "log_posts/\(id)"
        case .like(let id), .unlike(let id): return "log_posts/\(id)/like"
        case .save(let id), .unsave(let id): return "log_posts/\(id)/save"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .home, .feed, .detail, .userLogs: return .get
        case .create, .like, .save: return .post
        case .update: return .put
        case .delete, .unlike, .unsave: return .delete
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .feed(let cursor, let size):
            var items = [URLQueryItem(name: "size", value: "\(size)")]
            if let cursor = cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
            return items
        case .userLogs(_, let cursor):
            return cursor.map { [URLQueryItem(name: "cursor", value: $0)] }
        default: return nil
        }
    }

    var body: Encodable? {
        switch self {
        case .create(let req): return req
        case .update(_, let req): return req
        default: return nil
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .home, .feed, .detail, .userLogs: return false
        case .create, .update, .delete, .like, .unlike, .save, .unsave: return true
        }
    }
}

// MARK: - User Endpoints

enum UserEndpoint: APIEndpoint {
    case myProfile
    case profile(id: String)
    case updateProfile(UpdateProfileRequest)
    case checkUsername(String)
    case userRecipes(userId: String, cursor: String?)
    case follow(userId: String)
    case unfollow(userId: String)
    case followers(userId: String, cursor: String?)
    case following(userId: String, cursor: String?)
    case block(userId: String)
    case unblock(userId: String)
    case blockedUsers(page: Int)
    case report(userId: String, reason: ReportReason)
    case deleteAccount

    var path: String {
        switch self {
        case .myProfile, .deleteAccount: return "users/me"
        case .profile(let id): return "users/\(id)"
        case .updateProfile: return "users/me"
        case .checkUsername: return "users/check-username"
        case .userRecipes(let id, _): return "users/\(id)/recipes"
        case .follow(let id), .unfollow(let id): return "users/\(id)/follow"
        case .followers(let id, _): return "users/\(id)/followers"
        case .following(let id, _): return "users/\(id)/following"
        case .block(let id), .unblock(let id): return "users/\(id)/block"
        case .blockedUsers: return "users/me/blocked"
        case .report(let id, _): return "users/\(id)/report"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .myProfile, .profile, .checkUsername, .userRecipes, .followers, .following, .blockedUsers: return .get
        case .updateProfile: return .patch
        case .follow, .block, .report: return .post
        case .unfollow, .unblock, .deleteAccount: return .delete
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .checkUsername(let username):
            return [URLQueryItem(name: "username", value: username)]
        case .userRecipes(_, let cursor), .followers(_, let cursor), .following(_, let cursor):
            return cursor.map { [URLQueryItem(name: "cursor", value: $0)] }
        case .blockedUsers(let page):
            return [URLQueryItem(name: "page", value: String(page))]
        default: return nil
        }
    }

    var body: Encodable? {
        switch self {
        case .updateProfile(let req): return req
        case .report(_, let reason): return ["reason": reason.rawValue]
        default: return nil
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .checkUsername: return false
        default: return true
        }
    }
}

// MARK: - Comment Endpoints

enum CommentEndpoint: APIEndpoint {
    case list(logId: String, cursor: String?)
    case create(logId: String, content: String)
    case reply(parentCommentId: String, content: String)
    case update(id: String, content: String)
    case delete(id: String)
    case like(id: String)
    case unlike(id: String)

    var path: String {
        switch self {
        case .list(let logId, _): return "log_posts/\(logId)/comments"
        case .create(let logId, _): return "log_posts/\(logId)/comments"
        case .reply(let parentCommentId, _): return "comments/\(parentCommentId)/replies"
        case .update(let id, _), .delete(let id): return "comments/\(id)"
        case .like(let id), .unlike(let id): return "comments/\(id)/like"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list: return .get
        case .create, .reply, .like: return .post
        case .update: return .patch
        case .delete, .unlike: return .delete
        }
    }

    var queryItems: [URLQueryItem]? {
        if case .list(_, let cursor) = self {
            // Backend uses page-based pagination (Spring Page)
            var items = [URLQueryItem(name: "size", value: "20")]
            if let page = cursor { items.append(URLQueryItem(name: "page", value: page)) }
            return items
        }
        return nil
    }

    var body: Encodable? {
        switch self {
        case .create(_, let content), .reply(_, let content):
            return ["content": content]
        case .update(_, let content):
            return ["content": content]
        default:
            return nil
        }
    }
}

// MARK: - Search Endpoints

enum SearchEndpoint: APIEndpoint {
    case search(query: String, type: SearchType?, cursor: String?, size: Int)
    case recentSearches
    case clearRecentSearches
    case trending
    case hashtagContent(hashtag: String, type: SearchType?, cursor: String?)

    var path: String {
        switch self {
        case .search: return "search"
        case .recentSearches, .clearRecentSearches: return "search/history"
        case .trending: return "hashtags/popular"
        case .hashtagContent(let h, _, _): return "hashtags/\(h)/content"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .search, .recentSearches, .trending, .hashtagContent: return .get
        case .clearRecentSearches: return .delete
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .search(let q, let type, let cursor, let size):
            var items = [
                URLQueryItem(name: "q", value: q),
                URLQueryItem(name: "size", value: String(size))
            ]
            if let t = type, t != .all {
                items.append(URLQueryItem(name: "type", value: t.rawValue.lowercased()))
            }
            if let c = cursor {
                items.append(URLQueryItem(name: "cursor", value: c))
            }
            return items
        case .hashtagContent(_, let type, let cursor):
            var items: [URLQueryItem] = []
            if let t = type, t != .all { items.append(URLQueryItem(name: "type", value: t.rawValue)) }
            if let c = cursor { items.append(URLQueryItem(name: "cursor", value: c)) }
            return items.isEmpty ? nil : items
        default: return nil
        }
    }
}

// MARK: - Notification Endpoints

enum NotificationEndpoint: APIEndpoint {
    case list(cursor: String?)
    case unreadCount
    case markRead(id: String)
    case markAllRead
    case delete(id: String)
    case deleteAll
    case registerFCM(token: String)
    case unregisterFCM(token: String)

    var path: String {
        switch self {
        case .list, .deleteAll: return "notifications"
        case .unreadCount: return "notifications/unread-count"
        case .markRead(let id): return "notifications/\(id)/read"
        case .markAllRead: return "notifications/read-all"
        case .delete(let id): return "notifications/\(id)"
        case .registerFCM, .unregisterFCM: return "notifications/fcm-token"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list, .unreadCount: return .get
        case .markRead, .markAllRead: return .patch
        case .registerFCM: return .post
        case .delete, .deleteAll, .unregisterFCM: return .delete
        }
    }

    var queryItems: [URLQueryItem]? {
        if case .list(let cursor) = self { return cursor.map { [URLQueryItem(name: "cursor", value: $0)] } }
        return nil
    }

    var body: Encodable? {
        switch self {
        case .registerFCM(let token), .unregisterFCM(let token): return ["token": token]
        default: return nil
        }
    }
}

// MARK: - Saved Endpoints

enum SavedEndpoint: APIEndpoint {
    case recipes(cursor: String?)
    case logs(cursor: String?)

    var path: String {
        switch self {
        case .recipes: return "recipes/saved"
        case .logs: return "log_posts/saved"
        }
    }

    var method: HTTPMethod { .get }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .recipes(let cursor), .logs(let cursor):
            return cursor.map { [URLQueryItem(name: "cursor", value: $0)] }
        }
    }
}

// MARK: - View History Endpoints

enum ViewHistoryEndpoint: APIEndpoint {
    case recordRecipeView(id: String)
    case recordLogView(id: String)
    case recentRecipes(limit: Int)
    case recentLogs(limit: Int)

    var path: String {
        switch self {
        case .recordRecipeView(let id): return "view-history/recipes/\(id)"
        case .recordLogView(let id): return "view-history/logs/\(id)"
        case .recentRecipes: return "view-history/recipes"
        case .recentLogs: return "view-history/logs"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .recordRecipeView, .recordLogView: return .post
        case .recentRecipes, .recentLogs: return .get
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .recentRecipes(let limit), .recentLogs(let limit):
            return [URLQueryItem(name: "limit", value: "\(limit)")]
        default: return nil
        }
    }

    var requiresAuth: Bool { true }
}
