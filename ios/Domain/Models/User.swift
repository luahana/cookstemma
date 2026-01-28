import Foundation

// MARK: - User Summary

struct UserSummary: Codable, Identifiable, Equatable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let level: Int
    let isFollowing: Bool?

    enum CodingKeys: String, CodingKey {
        case id, visitorId = "publicId"
        case username, displayName, avatarUrl, profileImageUrl, level, isFollowing
    }

    // Memberwise initializer
    init(id: String, username: String, displayName: String?, avatarUrl: String?, level: Int, isFollowing: Bool?) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.level = level
        self.isFollowing = isFollowing
    }

    // Custom decoder to handle both "id" and "publicId"
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Try "id" first, then fall back to "publicId"
        if let id = try container.decodeIfPresent(String.self, forKey: .id) {
            self.id = id
        } else {
            self.id = try container.decode(String.self, forKey: .visitorId)
        }
        self.username = try container.decode(String.self, forKey: .username)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        self.avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
            ?? container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        self.level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 1
        self.isFollowing = try container.decodeIfPresent(Bool.self, forKey: .isFollowing)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encodeIfPresent(avatarUrl, forKey: .avatarUrl)
        try container.encode(level, forKey: .level)
        try container.encodeIfPresent(isFollowing, forKey: .isFollowing)
    }

    var displayNameOrUsername: String { displayName ?? username }
}

// MARK: - My Profile Response (matches backend MyProfileResponseDto)

struct MyProfile: Codable, Equatable {
    let user: UserInfo
    let recipeCount: Int
    let logCount: Int
    let savedCount: Int

    // Convenience accessors for backward compatibility
    var id: String { user.id }
    var username: String { user.username }
    var avatarUrl: String? { user.profileImageUrl }
    var level: Int { user.level }
    var followerCount: Int { user.followerCount }
    var followingCount: Int { user.followingCount }
    var bio: String? { user.bio }
    var levelProgress: Double { user.levelProgress ?? 0.0 }
    var measurementPreference: MeasurementPreference {
        MeasurementPreference(rawValue: user.measurementPreference ?? "METRIC") ?? .metric
    }
}

// MARK: - User Info (matches backend UserDto)

struct UserInfo: Codable, Identifiable, Equatable {
    let id: String
    let username: String
    let role: String
    let profileImageUrl: String?
    let gender: String?
    let locale: String?
    let defaultCookingStyle: String?
    let measurementPreference: String?
    let followerCount: Int
    let followingCount: Int
    let recipeCount: Int
    let logCount: Int
    let level: Int
    let levelName: String?
    let totalXp: Int?
    let xpForCurrentLevel: Int?
    let xpForNextLevel: Int?
    let levelProgress: Double?
    let bio: String?
    let youtubeUrl: String?
    let instagramHandle: String?

    var avatarUrl: String? { profileImageUrl }
}

// MARK: - User Profile

struct UserProfile: Codable, Identifiable, Equatable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let bio: String?
    let level: Int
    let recipeCount: Int
    let logCount: Int
    let followerCount: Int
    let followingCount: Int
    let socialLinks: SocialLinks?
    let isFollowing: Bool
    let isFollowedBy: Bool
    let isBlocked: Bool
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case username, displayName, avatarUrl, profileImageUrl, bio, level
        case recipeCount, logCount, followerCount, followingCount
        case socialLinks, isFollowing, isFollowedBy, isBlocked, createdAt
    }

    // Memberwise initializer for creating instances programmatically
    init(
        id: String,
        username: String,
        displayName: String?,
        avatarUrl: String?,
        bio: String?,
        level: Int,
        recipeCount: Int,
        logCount: Int,
        followerCount: Int,
        followingCount: Int,
        socialLinks: SocialLinks?,
        isFollowing: Bool,
        isFollowedBy: Bool,
        isBlocked: Bool,
        createdAt: Date?
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.bio = bio
        self.level = level
        self.recipeCount = recipeCount
        self.logCount = logCount
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.socialLinks = socialLinks
        self.isFollowing = isFollowing
        self.isFollowedBy = isFollowedBy
        self.isBlocked = isBlocked
        self.createdAt = createdAt
    }

    // Custom decoder to handle API response format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.username = try container.decode(String.self, forKey: .username)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        // Try avatarUrl first, fall back to profileImageUrl
        self.avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
            ?? container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        self.bio = try container.decodeIfPresent(String.self, forKey: .bio)
        self.level = try container.decode(Int.self, forKey: .level)
        self.recipeCount = try container.decode(Int.self, forKey: .recipeCount)
        self.logCount = try container.decode(Int.self, forKey: .logCount)
        self.followerCount = try container.decode(Int.self, forKey: .followerCount)
        self.followingCount = try container.decode(Int.self, forKey: .followingCount)
        self.socialLinks = try container.decodeIfPresent(SocialLinks.self, forKey: .socialLinks)
        self.isFollowing = try container.decodeIfPresent(Bool.self, forKey: .isFollowing) ?? false
        self.isFollowedBy = try container.decodeIfPresent(Bool.self, forKey: .isFollowedBy) ?? false
        self.isBlocked = try container.decodeIfPresent(Bool.self, forKey: .isBlocked) ?? false
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encodeIfPresent(avatarUrl, forKey: .avatarUrl)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encode(level, forKey: .level)
        try container.encode(recipeCount, forKey: .recipeCount)
        try container.encode(logCount, forKey: .logCount)
        try container.encode(followerCount, forKey: .followerCount)
        try container.encode(followingCount, forKey: .followingCount)
        try container.encodeIfPresent(socialLinks, forKey: .socialLinks)
        try container.encode(isFollowing, forKey: .isFollowing)
        try container.encode(isFollowedBy, forKey: .isFollowedBy)
        try container.encode(isBlocked, forKey: .isBlocked)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }

    var displayNameOrUsername: String { displayName ?? username }
}

// MARK: - Social Links

struct SocialLinks: Codable, Equatable {
    let youtube: String?
    let instagram: String?
    let twitter: String?
    let website: String?
}

// MARK: - Measurement Preference

enum MeasurementPreference: String, Codable, CaseIterable {
    case metric = "METRIC"
    case imperial = "IMPERIAL"

    var displayText: String {
        switch self {
        case .metric: return "Metric (g, ml)"
        case .imperial: return "Imperial (oz, cups)"
        }
    }
}

// MARK: - Update Profile Request

struct UpdateProfileRequest: Codable {
    let username: String?
    let bio: String?
    let avatarImageId: String?
    let socialLinks: SocialLinks?
    let measurementPreference: MeasurementPreference?
}

// MARK: - Username Availability Response

struct UsernameAvailabilityResponse: Codable {
    let available: Bool
}

// MARK: - Report Reason

enum ReportReason: String, Codable, CaseIterable {
    case spam = "SPAM"
    case harassment = "HARASSMENT"
    case inappropriateContent = "INAPPROPRIATE_CONTENT"
    case impersonation = "IMPERSONATION"
    case other = "OTHER"

    var displayText: String {
        switch self {
        case .spam: return "Spam"
        case .harassment: return "Harassment or bullying"
        case .inappropriateContent: return "Inappropriate content"
        case .impersonation: return "Impersonation"
        case .other: return "Other"
        }
    }
}

// MARK: - Blocked User

struct BlockedUser: Codable, Identifiable, Equatable {
    let id: String
    let username: String
    let avatarUrl: String?
    let blockedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case username
        case avatarUrl = "profileImageUrl"
        case blockedAt
    }

    var displayNameOrUsername: String { username }
}

// MARK: - Blocked Users Response

struct BlockedUsersResponse: Codable {
    let content: [BlockedUser]
    let hasNext: Bool
    let page: Int
    let size: Int
    let totalElements: Int

    var hasMore: Bool { hasNext }
    var nextPage: Int? { hasNext ? page + 1 : nil }
}
