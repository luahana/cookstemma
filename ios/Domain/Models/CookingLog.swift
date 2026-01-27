import Foundation

// MARK: - Home Feed Response

struct HomeFeedResponse: Codable {
    let recentActivity: [RecentActivityItem]
    let recentRecipes: [HomeRecipeItem]
    let trendingTrees: [TrendingTree]?
}

struct RecentActivityItem: Codable, Identifiable {
    let id: String
    let rating: Int
    let thumbnailUrl: String?
    let userName: String
    let recipeTitle: String
    let recipeId: String
    let foodName: String
    let createdAt: Date
    let hashtags: [String]
    let commentCount: Int

    enum CodingKeys: String, CodingKey {
        case id = "logPublicId"
        case rating, thumbnailUrl, userName, recipeTitle
        case recipeId = "recipePublicId"
        case foodName, createdAt, hashtags, commentCount
    }
}

struct HomeRecipeItem: Codable, Identifiable {
    let id: String
    let foodName: String
    let title: String
    let description: String?
    let cookingStyle: String?
    let userName: String
    let thumbnail: String?
    let variantCount: Int
    let logCount: Int
    let servings: Int?
    let cookingTimeRange: String?
    let hashtags: [String]

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case foodName, title, description, cookingStyle
        case userName, thumbnail, variantCount, logCount
        case servings, cookingTimeRange, hashtags
    }
}

struct TrendingTree: Codable, Identifiable {
    let id: String
    let title: String
    let foodName: String
    let cookingStyle: String?
    let thumbnail: String?
    let variantCount: Int
    let logCount: Int
    let latestChangeSummary: String?
    let userName: String

    enum CodingKeys: String, CodingKey {
        case id = "rootRecipeId"
        case title, foodName, cookingStyle, thumbnail
        case variantCount, logCount, latestChangeSummary, userName
    }
}

// MARK: - Feed Log Item (from /log_posts endpoint)

struct FeedLogItem: Codable, Identifiable, Equatable {
    let id: String
    let title: String?
    let content: String?
    let rating: Int?
    let thumbnailUrl: String?
    let creatorPublicId: String
    let userName: String
    let foodName: String?
    let recipeTitle: String?
    let hashtags: [String]
    let isVariant: Bool?
    let isPrivate: Bool?
    let commentCount: Int?
    let cookingStyle: String?

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case title, content, rating, thumbnailUrl
        case creatorPublicId, userName, foodName
        case recipeTitle, hashtags, isVariant
        case isPrivate, commentCount, cookingStyle
    }
}

// MARK: - Cooking Log Summary

struct CookingLogSummary: Codable, Identifiable, Equatable {
    let id: String
    let rating: Int
    let content: String?
    let images: [ImageInfo]
    let author: UserSummary
    let recipe: RecipeSummary?
    let likeCount: Int
    let commentCount: Int
    let isLiked: Bool
    let isSaved: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case rating, content, images, author
        case recipe, likeCount, commentCount
        case isLiked, isSaved, createdAt
    }
}

// MARK: - Cooking Log Detail

struct CookingLogDetail: Codable, Identifiable, Equatable {
    let id: String
    let title: String?
    let rating: Int
    let content: String?
    let logImages: [LogImageInfo]
    let linkedRecipe: LinkedRecipeSummary?
    let commentCount: Int
    let isSavedByCurrentUser: Bool?
    let hashtagObjects: [HashtagInfo]
    let isPrivate: Bool
    let creatorPublicId: String
    let userName: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case title, rating, content
        case logImages = "images"
        case linkedRecipe, commentCount
        case isSavedByCurrentUser
        case hashtagObjects = "hashtags"
        case isPrivate, creatorPublicId, userName, createdAt
    }

    // Computed properties for compatibility
    var images: [ImageInfo] {
        logImages.map { ImageInfo(id: $0.imagePublicId, url: $0.imageUrl, thumbnailUrl: $0.imageUrl, width: nil, height: nil) }
    }
    var author: UserSummary {
        UserSummary(id: creatorPublicId, username: userName, displayName: nil, avatarUrl: nil, level: 0, isFollowing: nil)
    }
    var recipe: RecipeSummary? {
        guard let r = linkedRecipe else { return nil }
        return RecipeSummary(
            id: r.id, title: r.title, description: r.description, foodName: r.foodName,
            cookingStyle: r.cookingStyle, userName: r.userName, thumbnail: r.thumbnail,
            variantCount: r.variantCount, logCount: r.logCount, servings: r.servings,
            cookingTimeRange: r.cookingTimeRange, hashtags: r.hashtags, isPrivate: r.isPrivate
        )
    }
    var likeCount: Int { 0 }
    var isLiked: Bool { false }
    var isSaved: Bool { isSavedByCurrentUser ?? false }
    var hashtags: [String] { hashtagObjects.map { $0.name } }
    var updatedAt: Date { createdAt }
}

// MARK: - Log Image Info (from API)
struct LogImageInfo: Codable, Identifiable, Equatable {
    let imagePublicId: String
    let imageUrl: String

    var id: String { imagePublicId }
}

// MARK: - Linked Recipe Summary (from log detail API)
struct LinkedRecipeSummary: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?
    let foodName: String
    let cookingStyle: String?
    let userName: String
    let thumbnail: String?
    let variantCount: Int
    let logCount: Int
    let servings: Int?
    let cookingTimeRange: String?
    let hashtags: [String]
    let isPrivate: Bool

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case title, description, foodName, cookingStyle
        case userName, thumbnail, variantCount, logCount
        case servings, cookingTimeRange, hashtags, isPrivate
    }

    var coverImageUrl: String? { thumbnail }
}

// MARK: - Image Info

struct ImageInfo: Codable, Identifiable, Equatable {
    let id: String
    let url: String
    let thumbnailUrl: String?
    let width: Int?
    let height: Int?

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case url, thumbnailUrl, width, height
    }
}

// MARK: - Feed Item

enum FeedItem: Codable, Identifiable, Equatable {
    case log(CookingLogSummary)
    case recipe(RecipeSummary)

    var id: String {
        switch self {
        case .log(let log): return "log_\(log.id)"
        case .recipe(let recipe): return "recipe_\(recipe.id)"
        }
    }

    enum CodingKeys: String, CodingKey {
        case type, log, recipe
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "LOG":
            self = .log(try container.decode(CookingLogSummary.self, forKey: .log))
        case "RECIPE":
            self = .recipe(try container.decode(RecipeSummary.self, forKey: .recipe))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type: \(type)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .log(let log):
            try container.encode("LOG", forKey: .type)
            try container.encode(log, forKey: .log)
        case .recipe(let recipe):
            try container.encode("RECIPE", forKey: .type)
            try container.encode(recipe, forKey: .recipe)
        }
    }
}

// MARK: - Create/Update Requests

struct CreateLogRequest: Codable {
    let rating: Int
    let content: String?
    let imageIds: [String]
    let recipeId: String?
    let hashtags: [String]
    let isPrivate: Bool
}

struct UpdateLogRequest: Codable {
    let rating: Int?
    let content: String?
    let imageIds: [String]?
    let recipeId: String?
    let hashtags: [String]?
    let isPrivate: Bool?
}
