import Foundation

struct AppNotification: Codable, Identifiable, Equatable {
    let id: String
    let type: NotificationType
    let title: String
    let body: String
    let isRead: Bool
    let actor: UserSummary?
    let targetId: String?
    let targetType: NotificationTargetType?
    let thumbnailUrl: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case type, title, body, isRead
        case actor, targetId, targetType, thumbnailUrl, createdAt
    }
}

enum NotificationType: String, Codable {
    case newFollower = "NEW_FOLLOWER"
    case logComment = "LOG_COMMENT"
    case commentReply = "COMMENT_REPLY"
    case commentLike = "COMMENT_LIKE"
    case recipeCooked = "RECIPE_COOKED"
    case recipeSaved = "RECIPE_SAVED"
    case logLike = "LOG_LIKE"
    case weeklyDigest = "WEEKLY_DIGEST"

    var iconName: String {
        switch self {
        case .newFollower: return "person.badge.plus"
        case .logComment, .commentReply: return "bubble.left"
        case .commentLike, .logLike: return "heart.fill"
        case .recipeCooked: return "frying.pan"
        case .recipeSaved: return "bookmark.fill"
        case .weeklyDigest: return "chart.bar"
        }
    }
}

enum NotificationTargetType: String, Codable {
    case recipe = "RECIPE"
    case log = "LOG"
    case user = "USER"
    case comment = "COMMENT"
}
