import XCTest
@testable import Cookstemma

final class CookingLogModelTests: XCTestCase {

    // MARK: - JSONDecoder Setup

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    // MARK: - CookingLogSummary Tests

    func testCookingLogSummary_parsesFromJSON() throws {
        // Given
        let json = """
        {
            "publicId": "log-123",
            "rating": 4,
            "content": "Made this for Sunday dinner and it turned out great!",
            "images": [
                {
                    "publicId": "img-1",
                    "url": "https://example.com/image1.jpg",
                    "thumbnailUrl": "https://example.com/thumb1.jpg",
                    "width": 800,
                    "height": 600
                },
                {
                    "publicId": "img-2",
                    "url": "https://example.com/image2.jpg",
                    "thumbnailUrl": "https://example.com/thumb2.jpg",
                    "width": 800,
                    "height": 600
                }
            ],
            "author": {
                "publicId": "user-1",
                "username": "homecook",
                "displayName": "Home Cook",
                "avatarUrl": "https://example.com/avatar.jpg",
                "level": 12,
                "isFollowing": true
            },
            "recipe": {
                "publicId": "recipe-1",
                "title": "Kimchi Fried Rice",
                "description": "Delicious Korean dish",
                "coverImageUrl": "https://example.com/recipe.jpg",
                "cookingTimeRange": "BETWEEN_15_AND_30_MIN",
                "servings": 2,
                "cookCount": 156,
                "averageRating": 4.3,
                "author": {
                    "publicId": "user-2",
                    "username": "chefkim",
                    "displayName": "Chef Kim",
                    "avatarUrl": null,
                    "level": 24,
                    "isFollowing": false
                },
                "isSaved": true,
                "category": null,
                "createdAt": "2024-01-01T00:00:00Z"
            },
            "likeCount": 42,
            "commentCount": 8,
            "isLiked": true,
            "isSaved": false,
            "createdAt": "2024-01-15T18:30:00Z"
        }
        """.data(using: .utf8)!

        // When
        let log = try decoder.decode(CookingLogSummary.self, from: json)

        // Then
        XCTAssertEqual(log.id, "log-123")
        XCTAssertEqual(log.rating, 4)
        XCTAssertEqual(log.content, "Made this for Sunday dinner and it turned out great!")
        XCTAssertEqual(log.images.count, 2)
        XCTAssertEqual(log.author.username, "homecook")
        XCTAssertEqual(log.recipe?.title, "Kimchi Fried Rice")
        XCTAssertEqual(log.likeCount, 42)
        XCTAssertEqual(log.commentCount, 8)
        XCTAssertTrue(log.isLiked)
        XCTAssertFalse(log.isSaved)
    }

    func testCookingLogSummary_withoutRecipe() throws {
        // Given - standalone log not linked to a recipe
        let json = """
        {
            "publicId": "log-456",
            "rating": 5,
            "content": "Just cooked something amazing!",
            "images": [
                {
                    "publicId": "img-1",
                    "url": "https://example.com/image.jpg",
                    "thumbnailUrl": null,
                    "width": null,
                    "height": null
                }
            ],
            "author": {
                "publicId": "user-1",
                "username": "cook",
                "displayName": null,
                "avatarUrl": null,
                "level": 5,
                "isFollowing": null
            },
            "recipe": null,
            "likeCount": 10,
            "commentCount": 2,
            "isLiked": false,
            "isSaved": false,
            "createdAt": "2024-01-16T12:00:00Z"
        }
        """.data(using: .utf8)!

        // When
        let log = try decoder.decode(CookingLogSummary.self, from: json)

        // Then
        XCTAssertNil(log.recipe)
        XCTAssertEqual(log.rating, 5)
    }

    func testCookingLogSummary_withEmptyImages() throws {
        // Given
        let json = createLogJSON(imageCount: 0)

        // When
        let log = try decoder.decode(CookingLogSummary.self, from: json)

        // Then
        XCTAssertTrue(log.images.isEmpty)
    }

    func testCookingLogSummary_withMaxImages() throws {
        // Given - up to 5 images allowed
        let json = createLogJSON(imageCount: 5)

        // When
        let log = try decoder.decode(CookingLogSummary.self, from: json)

        // Then
        XCTAssertEqual(log.images.count, 5)
    }

    // MARK: - CookingLogDetail Tests

    func testCookingLogDetail_parsesFromJSON() throws {
        // Given
        let json = """
        {
            "publicId": "log-789",
            "rating": 3,
            "content": "It was okay, could use more seasoning next time.",
            "images": [
                {
                    "publicId": "img-1",
                    "url": "https://example.com/image.jpg",
                    "thumbnailUrl": "https://example.com/thumb.jpg",
                    "width": 1200,
                    "height": 900
                }
            ],
            "author": {
                "publicId": "user-1",
                "username": "weekendchef",
                "displayName": "Weekend Chef",
                "avatarUrl": "https://example.com/avatar.jpg",
                "level": 8,
                "isFollowing": false
            },
            "recipe": null,
            "likeCount": 5,
            "commentCount": 1,
            "isLiked": false,
            "isSaved": true,
            "hashtags": ["homecooking", "dinner", "experiment"],
            "isPrivate": false,
            "createdAt": "2024-01-17T19:00:00Z",
            "updatedAt": "2024-01-17T19:30:00Z"
        }
        """.data(using: .utf8)!

        // When
        let log = try decoder.decode(CookingLogDetail.self, from: json)

        // Then
        XCTAssertEqual(log.id, "log-789")
        XCTAssertEqual(log.rating, 3)
        XCTAssertEqual(log.hashtags, ["homecooking", "dinner", "experiment"])
        XCTAssertFalse(log.isPrivate)
        XCTAssertTrue(log.isSaved)
    }

    func testCookingLogDetail_privateLog() throws {
        // Given
        let json = """
        {
            "publicId": "log-private",
            "rating": 2,
            "content": "Private experiment - not for public",
            "images": [],
            "author": {
                "publicId": "user-1",
                "username": "user",
                "displayName": null,
                "avatarUrl": null,
                "level": 1,
                "isFollowing": null
            },
            "recipe": null,
            "likeCount": 0,
            "commentCount": 0,
            "isLiked": false,
            "isSaved": false,
            "hashtags": [],
            "isPrivate": true,
            "createdAt": "2024-01-18T10:00:00Z",
            "updatedAt": "2024-01-18T10:00:00Z"
        }
        """.data(using: .utf8)!

        // When
        let log = try decoder.decode(CookingLogDetail.self, from: json)

        // Then
        XCTAssertTrue(log.isPrivate)
    }

    // MARK: - Rating Validation Tests

    func testRating_validRange() throws {
        // Valid ratings are 1-5
        for rating in 1...5 {
            let json = createLogJSON(rating: rating)
            let log = try decoder.decode(CookingLogSummary.self, from: json)
            XCTAssertEqual(log.rating, rating)
        }
    }

    // MARK: - ImageInfo Tests

    func testImageInfo_parsesAllFields() throws {
        // Given
        let json = """
        {
            "publicId": "img-123",
            "url": "https://example.com/full.jpg",
            "thumbnailUrl": "https://example.com/thumb.jpg",
            "width": 1920,
            "height": 1080
        }
        """.data(using: .utf8)!

        // When
        let image = try decoder.decode(ImageInfo.self, from: json)

        // Then
        XCTAssertEqual(image.id, "img-123")
        XCTAssertEqual(image.url, "https://example.com/full.jpg")
        XCTAssertEqual(image.thumbnailUrl, "https://example.com/thumb.jpg")
        XCTAssertEqual(image.width, 1920)
        XCTAssertEqual(image.height, 1080)
    }

    func testImageInfo_handlesNullOptionalFields() throws {
        // Given
        let json = """
        {
            "publicId": "img-456",
            "url": "https://example.com/image.jpg",
            "thumbnailUrl": null,
            "width": null,
            "height": null
        }
        """.data(using: .utf8)!

        // When
        let image = try decoder.decode(ImageInfo.self, from: json)

        // Then
        XCTAssertEqual(image.url, "https://example.com/image.jpg")
        XCTAssertNil(image.thumbnailUrl)
        XCTAssertNil(image.width)
        XCTAssertNil(image.height)
    }

    // MARK: - FeedItem Tests

    func testFeedItem_decodesLogType() throws {
        // Given
        let json = """
        {
            "type": "LOG",
            "log": {
                "publicId": "log-1",
                "rating": 4,
                "content": "Test log",
                "images": [],
                "author": {
                    "publicId": "user-1",
                    "username": "user",
                    "displayName": null,
                    "avatarUrl": null,
                    "level": 1,
                    "isFollowing": null
                },
                "recipe": null,
                "likeCount": 0,
                "commentCount": 0,
                "isLiked": false,
                "isSaved": false,
                "createdAt": "2024-01-01T00:00:00Z"
            }
        }
        """.data(using: .utf8)!

        // When
        let feedItem = try decoder.decode(FeedItem.self, from: json)

        // Then
        if case .log(let log) = feedItem {
            XCTAssertEqual(log.id, "log-1")
            XCTAssertEqual(feedItem.id, "log_log-1")
        } else {
            XCTFail("Expected log type")
        }
    }

    func testFeedItem_decodesRecipeType() throws {
        // Given
        let json = """
        {
            "type": "RECIPE",
            "recipe": {
                "publicId": "recipe-1",
                "title": "Test Recipe",
                "description": null,
                "coverImageUrl": null,
                "cookingTimeRange": null,
                "servings": null,
                "cookCount": 0,
                "averageRating": null,
                "author": {
                    "publicId": "user-1",
                    "username": "user",
                    "displayName": null,
                    "avatarUrl": null,
                    "level": 1,
                    "isFollowing": null
                },
                "isSaved": false,
                "category": null,
                "createdAt": "2024-01-01T00:00:00Z"
            }
        }
        """.data(using: .utf8)!

        // When
        let feedItem = try decoder.decode(FeedItem.self, from: json)

        // Then
        if case .recipe(let recipe) = feedItem {
            XCTAssertEqual(recipe.id, "recipe-1")
            XCTAssertEqual(feedItem.id, "recipe_recipe-1")
        } else {
            XCTFail("Expected recipe type")
        }
    }

    func testFeedItem_throwsOnUnknownType() {
        // Given
        let json = """
        {
            "type": "UNKNOWN",
            "data": {}
        }
        """.data(using: .utf8)!

        // Then
        XCTAssertThrowsError(try decoder.decode(FeedItem.self, from: json)) { error in
            guard case DecodingError.dataCorrupted = error else {
                XCTFail("Expected dataCorrupted error, got: \(error)")
                return
            }
        }
    }

    func testFeedItem_encodesLogType() throws {
        // Given
        let log = CookingLogSummary(
            id: "log-1",
            rating: 4,
            content: "Test",
            images: [],
            author: UserSummary(
                id: "user-1",
                username: "user",
                displayName: nil,
                avatarUrl: nil,
                level: 1,
                isFollowing: nil
            ),
            recipe: nil,
            likeCount: 0,
            commentCount: 0,
            isLiked: false,
            isSaved: false,
            createdAt: Date()
        )
        let feedItem = FeedItem.log(log)

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(feedItem)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then
        XCTAssertEqual(decoded?["type"] as? String, "LOG")
        XCTAssertNotNil(decoded?["log"])
    }

    // MARK: - CreateLogRequest Tests

    func testCreateLogRequest_encodes() throws {
        // Given
        let request = CreateLogRequest(
            rating: 5,
            content: "Amazing dish!",
            imageIds: ["img-1", "img-2"],
            recipeId: "recipe-123",
            hashtags: ["delicious", "homemade"],
            isPrivate: false
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then
        XCTAssertEqual(decoded?["rating"] as? Int, 5)
        XCTAssertEqual(decoded?["content"] as? String, "Amazing dish!")
        XCTAssertEqual(decoded?["imageIds"] as? [String], ["img-1", "img-2"])
        XCTAssertEqual(decoded?["recipeId"] as? String, "recipe-123")
        XCTAssertEqual(decoded?["hashtags"] as? [String], ["delicious", "homemade"])
        XCTAssertEqual(decoded?["isPrivate"] as? Bool, false)
    }

    func testCreateLogRequest_withNullOptionalFields() throws {
        // Given
        let request = CreateLogRequest(
            rating: 3,
            content: nil,
            imageIds: ["img-1"],
            recipeId: nil,
            hashtags: [],
            isPrivate: true
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then
        XCTAssertEqual(decoded?["rating"] as? Int, 3)
        XCTAssertNil(decoded?["content"] as? String)
        XCTAssertEqual(decoded?["isPrivate"] as? Bool, true)
    }

    // MARK: - Helpers

    private func createLogJSON(imageCount: Int = 1, rating: Int = 4) -> Data {
        var images: [[String: Any]] = []
        for i in 0..<imageCount {
            images.append([
                "publicId": "img-\(i)",
                "url": "https://example.com/img\(i).jpg",
                "thumbnailUrl": NSNull(),
                "width": NSNull(),
                "height": NSNull()
            ])
        }

        let log: [String: Any] = [
            "publicId": "log-test",
            "rating": rating,
            "content": "Test content",
            "images": images,
            "author": [
                "publicId": "user-1",
                "username": "test",
                "displayName": NSNull(),
                "avatarUrl": NSNull(),
                "level": 1,
                "isFollowing": NSNull()
            ],
            "recipe": NSNull(),
            "likeCount": 0,
            "commentCount": 0,
            "isLiked": false,
            "isSaved": false,
            "createdAt": "2024-01-01T00:00:00Z"
        ]

        return try! JSONSerialization.data(withJSONObject: log)
    }
}
