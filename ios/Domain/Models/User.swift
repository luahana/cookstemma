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

// MARK: - My Profile

struct MyProfile: Codable, Identifiable, Equatable {
    let id: String
    let username: String
    let displayName: String?
    let email: String?
    let avatarUrl: String?
    let bio: String?
    let level: Int
    let xp: Int
    let xpToNextLevel: Int
    let recipeCount: Int
    let logCount: Int
    let followerCount: Int
    let followingCount: Int
    let socialLinks: SocialLinks?
    let measurementPreference: MeasurementPreference
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case username, displayName, email, avatarUrl
        case bio, level, xp, xpToNextLevel
        case recipeCount, logCount, followerCount, followingCount
        case socialLinks, measurementPreference, createdAt
    }

    var levelProgress: Double {
        guard xpToNextLevel > 0 else { return 1.0 }
        return Double(xp % xpToNextLevel) / Double(xpToNextLevel)
    }
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
    let displayName: String?
    let bio: String?
    let avatarImageId: String?
    let socialLinks: SocialLinks?
    let measurementPreference: MeasurementPreference?
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
