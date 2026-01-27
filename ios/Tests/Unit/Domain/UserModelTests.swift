import XCTest
@testable import Cookstemma

final class UserModelTests: XCTestCase {

    // MARK: - JSONDecoder Setup

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    // MARK: - UserSummary Tests

    func testUserSummary_parsesFromJSON() throws {
        // Given
        let json = """
        {
            "publicId": "user-123",
            "username": "chefkim",
            "displayName": "Chef Kim",
            "avatarUrl": "https://example.com/avatar.jpg",
            "level": 24,
            "isFollowing": true
        }
        """.data(using: .utf8)!

        // When
        let user = try decoder.decode(UserSummary.self, from: json)

        // Then
        XCTAssertEqual(user.id, "user-123")
        XCTAssertEqual(user.username, "chefkim")
        XCTAssertEqual(user.displayName, "Chef Kim")
        XCTAssertEqual(user.avatarUrl, "https://example.com/avatar.jpg")
        XCTAssertEqual(user.level, 24)
        XCTAssertEqual(user.isFollowing, true)
    }

    func testUserSummary_handlesNullOptionalFields() throws {
        // Given
        let json = """
        {
            "publicId": "user-456",
            "username": "newuser",
            "displayName": null,
            "avatarUrl": null,
            "level": 1,
            "isFollowing": null
        }
        """.data(using: .utf8)!

        // When
        let user = try decoder.decode(UserSummary.self, from: json)

        // Then
        XCTAssertEqual(user.username, "newuser")
        XCTAssertNil(user.displayName)
        XCTAssertNil(user.avatarUrl)
        XCTAssertNil(user.isFollowing)
    }

    func testUserSummary_displayNameOrUsername_returnsDisplayName() {
        // Given
        let user = UserSummary(
            id: "user-1",
            username: "john_doe",
            displayName: "John Doe",
            avatarUrl: nil,
            level: 5,
            isFollowing: nil
        )

        // Then
        XCTAssertEqual(user.displayNameOrUsername, "John Doe")
    }

    func testUserSummary_displayNameOrUsername_fallsBackToUsername() {
        // Given
        let user = UserSummary(
            id: "user-1",
            username: "jane_doe",
            displayName: nil,
            avatarUrl: nil,
            level: 5,
            isFollowing: nil
        )

        // Then
        XCTAssertEqual(user.displayNameOrUsername, "jane_doe")
    }

    // MARK: - MyProfile Tests

    func testMyProfile_parsesFromJSON() throws {
        // Given
        let json = """
        {
            "publicId": "user-me",
            "username": "myusername",
            "displayName": "My Display Name",
            "email": "me@example.com",
            "avatarUrl": "https://example.com/myavatar.jpg",
            "bio": "I love cooking!",
            "level": 12,
            "xp": 2450,
            "xpToNextLevel": 1000,
            "recipeCount": 15,
            "logCount": 89,
            "followerCount": 1200,
            "followingCount": 350,
            "socialLinks": {
                "youtube": "https://youtube.com/@mychannel",
                "instagram": "@myinsta",
                "twitter": "@mytwitter",
                "website": "https://myblog.com"
            },
            "measurementPreference": "METRIC",
            "createdAt": "2023-06-15T08:00:00Z"
        }
        """.data(using: .utf8)!

        // When
        let profile = try decoder.decode(MyProfile.self, from: json)

        // Then
        XCTAssertEqual(profile.id, "user-me")
        XCTAssertEqual(profile.username, "myusername")
        XCTAssertEqual(profile.displayName, "My Display Name")
        XCTAssertEqual(profile.email, "me@example.com")
        XCTAssertEqual(profile.bio, "I love cooking!")
        XCTAssertEqual(profile.level, 12)
        XCTAssertEqual(profile.xp, 2450)
        XCTAssertEqual(profile.xpToNextLevel, 1000)
        XCTAssertEqual(profile.recipeCount, 15)
        XCTAssertEqual(profile.logCount, 89)
        XCTAssertEqual(profile.followerCount, 1200)
        XCTAssertEqual(profile.followingCount, 350)
        XCTAssertEqual(profile.measurementPreference, .metric)
        XCTAssertEqual(profile.socialLinks?.youtube, "https://youtube.com/@mychannel")
        XCTAssertEqual(profile.socialLinks?.instagram, "@myinsta")
    }

    func testMyProfile_levelProgressCalculation() throws {
        // Given - xp = 2450, xpToNextLevel = 1000 → progress = (2450 % 1000) / 1000 = 450/1000 = 0.45
        let json = """
        {
            "publicId": "user-1",
            "username": "user",
            "displayName": null,
            "email": null,
            "avatarUrl": null,
            "bio": null,
            "level": 12,
            "xp": 2450,
            "xpToNextLevel": 1000,
            "recipeCount": 0,
            "logCount": 0,
            "followerCount": 0,
            "followingCount": 0,
            "socialLinks": null,
            "measurementPreference": "METRIC",
            "createdAt": "2024-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        // When
        let profile = try decoder.decode(MyProfile.self, from: json)

        // Then
        XCTAssertEqual(profile.levelProgress, 0.45, accuracy: 0.001)
    }

    func testMyProfile_levelProgressAtZeroXPToNextLevel() throws {
        // Given - xpToNextLevel = 0 should return 1.0 (max level)
        let json = """
        {
            "publicId": "user-1",
            "username": "maxlevel",
            "displayName": null,
            "email": null,
            "avatarUrl": null,
            "bio": null,
            "level": 100,
            "xp": 99999,
            "xpToNextLevel": 0,
            "recipeCount": 0,
            "logCount": 0,
            "followerCount": 0,
            "followingCount": 0,
            "socialLinks": null,
            "measurementPreference": "METRIC",
            "createdAt": "2024-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        // When
        let profile = try decoder.decode(MyProfile.self, from: json)

        // Then
        XCTAssertEqual(profile.levelProgress, 1.0)
    }

    // MARK: - UserProfile Tests

    func testUserProfile_parsesFromJSON() throws {
        // Given
        let json = """
        {
            "publicId": "user-other",
            "username": "otherusername",
            "displayName": "Other User",
            "avatarUrl": "https://example.com/other.jpg",
            "bio": "Food blogger and recipe creator",
            "level": 24,
            "recipeCount": 45,
            "logCount": 203,
            "followerCount": 5200,
            "followingCount": 150,
            "socialLinks": {
                "youtube": "https://youtube.com/@otheruser",
                "instagram": "@otheruser",
                "twitter": null,
                "website": null
            },
            "isFollowing": true,
            "isFollowedBy": false,
            "isBlocked": false,
            "createdAt": "2022-03-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        // When
        let profile = try decoder.decode(UserProfile.self, from: json)

        // Then
        XCTAssertEqual(profile.id, "user-other")
        XCTAssertEqual(profile.username, "otherusername")
        XCTAssertEqual(profile.displayName, "Other User")
        XCTAssertEqual(profile.level, 24)
        XCTAssertEqual(profile.followerCount, 5200)
        XCTAssertTrue(profile.isFollowing)
        XCTAssertFalse(profile.isFollowedBy)
        XCTAssertFalse(profile.isBlocked)
    }

    func testUserProfile_displayNameOrUsername() {
        // Given - with display name
        let profileWithDisplayName = UserProfile(
            id: "1",
            username: "user",
            displayName: "Display Name",
            avatarUrl: nil,
            bio: nil,
            level: 1,
            recipeCount: 0,
            logCount: 0,
            followerCount: 0,
            followingCount: 0,
            socialLinks: nil,
            isFollowing: false,
            isFollowedBy: false,
            isBlocked: false,
            createdAt: Date()
        )

        // Given - without display name
        let profileWithoutDisplayName = UserProfile(
            id: "2",
            username: "username_only",
            displayName: nil,
            avatarUrl: nil,
            bio: nil,
            level: 1,
            recipeCount: 0,
            logCount: 0,
            followerCount: 0,
            followingCount: 0,
            socialLinks: nil,
            isFollowing: false,
            isFollowedBy: false,
            isBlocked: false,
            createdAt: Date()
        )

        // Then
        XCTAssertEqual(profileWithDisplayName.displayNameOrUsername, "Display Name")
        XCTAssertEqual(profileWithoutDisplayName.displayNameOrUsername, "username_only")
    }

    func testUserProfile_blockedUser() throws {
        // Given
        let json = """
        {
            "publicId": "user-blocked",
            "username": "blockeduser",
            "displayName": "Blocked User",
            "avatarUrl": null,
            "bio": null,
            "level": 5,
            "recipeCount": 10,
            "logCount": 20,
            "followerCount": 100,
            "followingCount": 50,
            "socialLinks": null,
            "isFollowing": false,
            "isFollowedBy": false,
            "isBlocked": true,
            "createdAt": "2023-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        // When
        let profile = try decoder.decode(UserProfile.self, from: json)

        // Then
        XCTAssertTrue(profile.isBlocked)
        XCTAssertFalse(profile.isFollowing)
    }

    // MARK: - SocialLinks Tests

    func testSocialLinks_parsesAllFields() throws {
        // Given
        let json = """
        {
            "youtube": "https://youtube.com/@channel",
            "instagram": "@instahandle",
            "twitter": "@twitterhandle",
            "website": "https://mysite.com"
        }
        """.data(using: .utf8)!

        // When
        let links = try decoder.decode(SocialLinks.self, from: json)

        // Then
        XCTAssertEqual(links.youtube, "https://youtube.com/@channel")
        XCTAssertEqual(links.instagram, "@instahandle")
        XCTAssertEqual(links.twitter, "@twitterhandle")
        XCTAssertEqual(links.website, "https://mysite.com")
    }

    func testSocialLinks_handlesAllNull() throws {
        // Given
        let json = """
        {
            "youtube": null,
            "instagram": null,
            "twitter": null,
            "website": null
        }
        """.data(using: .utf8)!

        // When
        let links = try decoder.decode(SocialLinks.self, from: json)

        // Then
        XCTAssertNil(links.youtube)
        XCTAssertNil(links.instagram)
        XCTAssertNil(links.twitter)
        XCTAssertNil(links.website)
    }

    // MARK: - MeasurementPreference Tests

    func testMeasurementPreference_allCases() throws {
        let testCases: [(String, MeasurementPreference, String)] = [
            ("METRIC", .metric, "Metric (g, ml)"),
            ("IMPERIAL", .imperial, "Imperial (oz, cups)")
        ]

        for (jsonValue, expectedCase, expectedDisplayText) in testCases {
            let json = "\"\(jsonValue)\"".data(using: .utf8)!
            let result = try decoder.decode(MeasurementPreference.self, from: json)
            XCTAssertEqual(result, expectedCase)
            XCTAssertEqual(result.displayText, expectedDisplayText)
        }
    }

    // MARK: - UpdateProfileRequest Tests

    func testUpdateProfileRequest_encodesAllFields() throws {
        // Given
        let request = UpdateProfileRequest(
            displayName: "New Name",
            bio: "Updated bio",
            avatarImageId: "img-123",
            socialLinks: SocialLinks(
                youtube: "https://youtube.com",
                instagram: "@new",
                twitter: nil,
                website: nil
            ),
            measurementPreference: .imperial
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then
        XCTAssertEqual(decoded?["displayName"] as? String, "New Name")
        XCTAssertEqual(decoded?["bio"] as? String, "Updated bio")
        XCTAssertEqual(decoded?["avatarImageId"] as? String, "img-123")
        XCTAssertNotNil(decoded?["socialLinks"])
        XCTAssertEqual(decoded?["measurementPreference"] as? String, "IMPERIAL")
    }

    func testUpdateProfileRequest_partialUpdate() throws {
        // Given - only updating display name
        let request = UpdateProfileRequest(
            displayName: "Just New Name",
            bio: nil,
            avatarImageId: nil,
            socialLinks: nil,
            measurementPreference: nil
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then
        XCTAssertEqual(decoded?["displayName"] as? String, "Just New Name")
    }

    // MARK: - ReportReason Tests

    func testReportReason_allCases() throws {
        let testCases: [(String, ReportReason, String)] = [
            ("SPAM", .spam, "Spam"),
            ("HARASSMENT", .harassment, "Harassment or bullying"),
            ("INAPPROPRIATE_CONTENT", .inappropriateContent, "Inappropriate content"),
            ("IMPERSONATION", .impersonation, "Impersonation"),
            ("OTHER", .other, "Other")
        ]

        for (jsonValue, expectedCase, expectedDisplayText) in testCases {
            let json = "\"\(jsonValue)\"".data(using: .utf8)!
            let result = try decoder.decode(ReportReason.self, from: json)
            XCTAssertEqual(result, expectedCase)
            XCTAssertEqual(result.displayText, expectedDisplayText)
        }
    }

    // MARK: - Equatable Tests

    func testUserSummary_equatable() {
        let user1 = UserSummary(
            id: "user-1",
            username: "user",
            displayName: "User",
            avatarUrl: nil,
            level: 5,
            isFollowing: true
        )

        let user2 = UserSummary(
            id: "user-1",
            username: "user",
            displayName: "User",
            avatarUrl: nil,
            level: 5,
            isFollowing: true
        )

        let user3 = UserSummary(
            id: "user-2",
            username: "other",
            displayName: nil,
            avatarUrl: nil,
            level: 1,
            isFollowing: false
        )

        XCTAssertEqual(user1, user2)
        XCTAssertNotEqual(user1, user3)
    }
}
