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
        case id = "publicId"
        case username, displayName, avatarUrl, level, isFollowing
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
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case username, displayName, avatarUrl, bio, level
        case recipeCount, logCount, followerCount, followingCount
        case socialLinks, isFollowing, isFollowedBy, isBlocked, createdAt
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
