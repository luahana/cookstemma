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
        case id, visitorId = "publicId"
        case type, title, body, isRead
        case actor, targetId, targetType, thumbnailUrl, createdAt
    }

    // Memberwise initializer
    init(
        id: String,
        type: NotificationType,
        title: String,
        body: String,
        isRead: Bool,
        actor: UserSummary?,
        targetId: String?,
        targetType: NotificationTargetType?,
        thumbnailUrl: String?,
        createdAt: Date
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.body = body
        self.isRead = isRead
        self.actor = actor
        self.targetId = targetId
        self.targetType = targetType
        self.thumbnailUrl = thumbnailUrl
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Try "id" first, then fall back to "publicId"
        if let id = try container.decodeIfPresent(String.self, forKey: .id) {
            self.id = id
        } else {
            self.id = try container.decode(String.self, forKey: .visitorId)
        }
        self.type = try container.decode(NotificationType.self, forKey: .type)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        self.isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        self.actor = try container.decodeIfPresent(UserSummary.self, forKey: .actor)
        self.targetId = try container.decodeIfPresent(String.self, forKey: .targetId)
        self.targetType = try container.decodeIfPresent(NotificationTargetType.self, forKey: .targetType)
        self.thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encode(body, forKey: .body)
        try container.encode(isRead, forKey: .isRead)
        try container.encodeIfPresent(actor, forKey: .actor)
        try container.encodeIfPresent(targetId, forKey: .targetId)
        try container.encodeIfPresent(targetType, forKey: .targetType)
        try container.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
        try container.encode(createdAt, forKey: .createdAt)
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
    case unknown = "UNKNOWN"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = NotificationType(rawValue: rawValue) ?? .unknown
    }

    var iconName: String {
        switch self {
        case .newFollower: return "person.badge.plus"
        case .logComment, .commentReply: return "bubble.left"
        case .commentLike, .logLike: return "heart.fill"
        case .recipeCooked: return "frying.pan"
        case .recipeSaved: return "bookmark.fill"
        case .weeklyDigest: return "chart.bar"
        case .unknown: return "bell"
        }
    }
}

enum NotificationTargetType: String, Codable {
    case recipe = "RECIPE"
    case log = "LOG"
    case user = "USER"
    case comment = "COMMENT"
}
