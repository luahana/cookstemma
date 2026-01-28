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
        // Given - MyProfile now wraps UserInfo as per backend MyProfileResponseDto
        let json = """
        {
            "user": {
                "id": "user-me",
                "username": "myusername",
                "role": "USER",
                "profileImageUrl": "https://example.com/myavatar.jpg",
                "gender": null,
                "locale": "en",
                "defaultCookingStyle": null,
                "measurementPreference": "METRIC",
                "followerCount": 1200,
                "followingCount": 350,
                "recipeCount": 15,
                "logCount": 89,
                "level": 12,
                "levelName": "homeCook",
                "totalXp": 2450,
                "xpForCurrentLevel": 450,
                "xpForNextLevel": 1000,
                "levelProgress": 0.45,
                "bio": "I love cooking!",
                "youtubeUrl": "https://youtube.com/@mychannel",
                "instagramHandle": "@myinsta"
            },
            "recipeCount": 15,
            "logCount": 89,
            "savedCount": 5
        }
        """.data(using: .utf8)!

        // When
        let profile = try decoder.decode(MyProfile.self, from: json)

        // Then
        XCTAssertEqual(profile.id, "user-me")
        XCTAssertEqual(profile.username, "myusername")
        XCTAssertEqual(profile.bio, "I love cooking!")
        XCTAssertEqual(profile.level, 12)
        XCTAssertEqual(profile.recipeCount, 15)
        XCTAssertEqual(profile.logCount, 89)
        XCTAssertEqual(profile.followerCount, 1200)
        XCTAssertEqual(profile.followingCount, 350)
        XCTAssertEqual(profile.measurementPreference, .metric)
        XCTAssertEqual(profile.youtubeUrl, "https://youtube.com/@mychannel")
        XCTAssertEqual(profile.instagramHandle, "@myinsta")
    }

    func testMyProfile_levelProgressFromBackend() throws {
        // Given - levelProgress is now returned directly from backend
        let json = """
        {
            "user": {
                "id": "user-1",
                "username": "user",
                "role": "USER",
                "profileImageUrl": null,
                "gender": null,
                "locale": "en",
                "defaultCookingStyle": null,
                "measurementPreference": "METRIC",
                "followerCount": 0,
                "followingCount": 0,
                "recipeCount": 0,
                "logCount": 0,
                "level": 12,
                "levelName": "homeCook",
                "totalXp": 2450,
                "xpForCurrentLevel": 450,
                "xpForNextLevel": 1000,
                "levelProgress": 0.45,
                "bio": null,
                "youtubeUrl": null,
                "instagramHandle": null
            },
            "recipeCount": 0,
            "logCount": 0,
            "savedCount": 0
        }
        """.data(using: .utf8)!

        // When
        let profile = try decoder.decode(MyProfile.self, from: json)

        // Then
        XCTAssertEqual(profile.levelProgress, 0.45, accuracy: 0.001)
    }

    func testMyProfile_levelProgressDefaults() throws {
        // Given - levelProgress is nil, should default to 0.0
        let json = """
        {
            "user": {
                "id": "user-1",
                "username": "maxlevel",
                "role": "USER",
                "profileImageUrl": null,
                "gender": null,
                "locale": "en",
                "defaultCookingStyle": null,
                "measurementPreference": "METRIC",
                "followerCount": 0,
                "followingCount": 0,
                "recipeCount": 0,
                "logCount": 0,
                "level": 100,
                "levelName": "masterChef",
                "totalXp": 99999,
                "xpForCurrentLevel": null,
                "xpForNextLevel": null,
                "levelProgress": null,
                "bio": null,
                "youtubeUrl": null,
                "instagramHandle": null
            },
            "recipeCount": 0,
            "logCount": 0,
            "savedCount": 0
        }
        """.data(using: .utf8)!

        // When
        let profile = try decoder.decode(MyProfile.self, from: json)

        // Then - defaults to 0.0 when nil
        XCTAssertEqual(profile.levelProgress, 0.0)
    }

    // MARK: - UserProfile Tests

    func testUserProfile_parsesFromJSON() throws {
        // Given
        let json = """
        {
            "id": "user-other",
            "username": "otherusername",
            "displayName": "Other User",
            "avatarUrl": "https://example.com/other.jpg",
            "bio": "Food blogger and recipe creator",
            "level": 24,
            "levelName": "skilledCook",
            "recipeCount": 45,
            "logCount": 203,
            "followerCount": 5200,
            "followingCount": 150,
            "youtubeUrl": "https://youtube.com/@otheruser",
            "instagramHandle": "@otheruser",
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
        XCTAssertEqual(profile.levelName, "skilledCook")
        XCTAssertEqual(profile.followerCount, 5200)
        XCTAssertEqual(profile.youtubeUrl, "https://youtube.com/@otheruser")
        XCTAssertEqual(profile.instagramHandle, "@otheruser")
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
            levelName: nil,
            recipeCount: 0,
            logCount: 0,
            followerCount: 0,
            followingCount: 0,
            youtubeUrl: nil,
            instagramHandle: nil,
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
            levelName: nil,
            recipeCount: 0,
            logCount: 0,
            followerCount: 0,
            followingCount: 0,
            youtubeUrl: nil,
            instagramHandle: nil,
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
            "id": "user-blocked",
            "username": "blockeduser",
            "displayName": "Blocked User",
            "avatarUrl": null,
            "bio": null,
            "level": 5,
            "levelName": null,
            "recipeCount": 10,
            "logCount": 20,
            "followerCount": 100,
            "followingCount": 50,
            "youtubeUrl": null,
            "instagramHandle": null,
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
            ("ORIGINAL", .original, "Original"),
            ("METRIC", .metric, "Metric"),
            ("US", .us, "US")
        ]

        for (jsonValue, expectedCase, expectedDisplayName) in testCases {
            let json = "\"\(jsonValue)\"".data(using: .utf8)!
            let result = try decoder.decode(MeasurementPreference.self, from: json)
            XCTAssertEqual(result, expectedCase)
            XCTAssertEqual(result.displayName, expectedDisplayName)
        }
    }

    // MARK: - UpdateProfileRequest Tests

    func testUpdateProfileRequest_encodesAllFields() throws {
        // Given
        let request = UpdateProfileRequest(
            username: "newusername",
            bio: "Updated bio",
            avatarImageId: "img-123",
            youtubeUrl: "https://youtube.com",
            instagramHandle: "@new",
            measurementPreference: .us
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then
        XCTAssertEqual(decoded?["username"] as? String, "newusername")
        XCTAssertEqual(decoded?["bio"] as? String, "Updated bio")
        XCTAssertEqual(decoded?["avatarImageId"] as? String, "img-123")
        XCTAssertEqual(decoded?["youtubeUrl"] as? String, "https://youtube.com")
        XCTAssertEqual(decoded?["instagramHandle"] as? String, "@new")
        XCTAssertEqual(decoded?["measurementPreference"] as? String, "US")
    }

    func testUpdateProfileRequest_partialUpdate() throws {
        // Given - only updating username
        let request = UpdateProfileRequest(
            username: "newusername",
            bio: nil,
            avatarImageId: nil,
            youtubeUrl: nil,
            instagramHandle: nil,
            measurementPreference: nil
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then
        XCTAssertEqual(decoded?["username"] as? String, "newusername")
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
