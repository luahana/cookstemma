import Foundation

// MARK: - Search Response (API Response)

struct SearchResponse: Codable, Equatable {
    let recipes: [RecipeSummary]
    let logs: [CookingLogSummary]
    let users: [UserSummary]
    let hashtags: [HashtagCount]
    let totalCount: Int?
    let cursor: String?
}

// MARK: - Unified Search Response (matches backend)

struct UnifiedSearchResponse: Codable {
    let content: [SearchResultItem]
    let counts: SearchCountsResponse
    let page: Int
    let size: Int
    let totalElements: Int
    let totalPages: Int
    let hasNext: Bool
    let nextCursor: String?
}

struct SearchCountsResponse: Codable, Equatable {
    let recipes: Int
    let logs: Int
    let hashtags: Int
    let total: Int
}

struct SearchResultItem: Codable {
    let type: String
    let relevanceScore: Double?
    let data: SearchItemData
}

enum SearchItemData: Codable {
    case recipe(RecipeSummary)
    case log(LogPostSummaryResponse)
    case hashtag(HashtagSearchResult)
    case user(UserSummary)
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // Try to decode as recipe first (most common)
        if let recipe = try? container.decode(RecipeSummary.self) {
            self = .recipe(recipe)
            return
        }
        // Try log
        if let log = try? container.decode(LogPostSummaryResponse.self) {
            self = .log(log)
            return
        }
        // Try hashtag
        if let hashtag = try? container.decode(HashtagSearchResult.self) {
            self = .hashtag(hashtag)
            return
        }
        // Try user
        if let user = try? container.decode(UserSummary.self) {
            self = .user(user)
            return
        }
        // Unknown type
        self = .unknown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .recipe(let recipe): try container.encode(recipe)
        case .log(let log): try container.encode(log)
        case .hashtag(let hashtag): try container.encode(hashtag)
        case .user(let user): try container.encode(user)
        case .unknown: try container.encodeNil()
        }
    }
}

/// Log post summary as returned by backend search API
struct LogPostSummaryResponse: Codable, Identifiable, Equatable {
    let id: String
    let title: String?
    let content: String?
    let rating: Int?
    let thumbnailUrl: String?
    let creatorPublicId: String?
    let userName: String
    let foodName: String?
    let recipeTitle: String?
    let hashtags: [String]
    let isVariant: Bool?
    let isPrivate: Bool?
    let commentCount: Int?
    let locale: String?

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case title, content, rating, thumbnailUrl
        case creatorPublicId, userName, foodName, recipeTitle
        case hashtags, isVariant, isPrivate, commentCount, locale
    }
}

struct HashtagSearchResult: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let recipeCount: Int
    let logCount: Int
    let sampleThumbnails: [String]?
    let topContributors: [ContributorPreview]?

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case name, recipeCount, logCount, sampleThumbnails, topContributors
    }

    var totalCount: Int { recipeCount + logCount }
}

struct ContributorPreview: Codable, Equatable {
    let publicId: String
    let username: String
    let avatarUrl: String?
}

// MARK: - Hashtag Count (for trending/search results)

struct HashtagCount: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let postCount: Int

    var displayName: String { "#\(name)" }

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case name
        case postCount = "totalCount"
    }

    init(id: String = UUID().uuidString, name: String, postCount: Int) {
        self.id = id
        self.name = name
        self.postCount = postCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.name = try container.decode(String.self, forKey: .name)
        self.postCount = try container.decode(Int.self, forKey: .postCount)
    }
}

// MARK: - Search Result (unified result type)

enum SearchResult: Equatable {
    case recipe(RecipeSummary)
    case log(CookingLogSummary)
    case user(UserSummary)
    case hashtag(HashtagCount)
}

// MARK: - Search Type

enum SearchType: String, Codable, CaseIterable {
    case all = "ALL"
    case recipes = "RECIPES"
    case logs = "LOGS"
    case users = "USERS"
    case hashtags = "HASHTAGS"

    var displayText: String {
        switch self {
        case .all: return "All"
        case .recipes: return "Recipes"
        case .logs: return "Logs"
        case .users: return "Users"
        case .hashtags: return "Hashtags"
        }
    }
}

struct SearchResults: Codable, Equatable {
    let recipes: [RecipeSummary]
    let logs: [CookingLogSummary]
    let users: [UserSummary]
    let hashtags: [HashtagResult]
    let topResult: TopSearchResult?
    let counts: SearchCounts

    struct SearchCounts: Codable, Equatable {
        let recipes: Int
        let logs: Int
        let users: Int
        let hashtags: Int
    }
}

enum TopSearchResult: Codable, Equatable {
    case recipe(RecipeSummary)
    case log(CookingLogSummary)
    case user(UserSummary)
    case hashtag(HashtagResult)

    enum CodingKeys: String, CodingKey {
        case type, recipe, log, user, hashtag
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "RECIPE": self = .recipe(try container.decode(RecipeSummary.self, forKey: .recipe))
        case "LOG": self = .log(try container.decode(CookingLogSummary.self, forKey: .log))
        case "USER": self = .user(try container.decode(UserSummary.self, forKey: .user))
        case "HASHTAG": self = .hashtag(try container.decode(HashtagResult.self, forKey: .hashtag))
        default: throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .recipe(let r): try container.encode("RECIPE", forKey: .type); try container.encode(r, forKey: .recipe)
        case .log(let l): try container.encode("LOG", forKey: .type); try container.encode(l, forKey: .log)
        case .user(let u): try container.encode("USER", forKey: .type); try container.encode(u, forKey: .user)
        case .hashtag(let h): try container.encode("HASHTAG", forKey: .type); try container.encode(h, forKey: .hashtag)
        }
    }
}

struct HashtagResult: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let postCount: Int

    var displayName: String { "#\(name)" }
}

struct RecentSearch: Codable, Identifiable, Equatable {
    let id: String
    let query: String
    let type: SearchType?
    let searchedAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case query, type, searchedAt
    }
}

struct TrendingHashtag: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let postCount: Int
    let weeklyGrowth: Double?

    var displayName: String { "#\(name)" }

    var formattedPostCount: String {
        postCount >= 1000 ? String(format: "%.1fK", Double(postCount) / 1000) : "\(postCount)"
    }
}

// MARK: - Hashtag Content Response

struct HashtagContentResponse: Codable {
    let content: [HashtagContentItem]
    let totalElements: Int?
    let totalPages: Int?
    let currentPage: Int?
    let nextCursor: String?
    let hasNext: Bool
    let size: Int
}

struct HashtagContentItem: Codable, Identifiable, Equatable {
    let id: String
    let type: String  // "recipe" or "log"
    let title: String?
    let thumbnailUrl: String?
    let creatorPublicId: String
    let userName: String
    let hashtags: [String]
    let foodName: String?
    let cookingStyle: String?
    let rating: Int?
    let recipeTitle: String?
    let isPrivate: Bool?

    var isRecipe: Bool { type == "recipe" }
    var isLog: Bool { type == "log" }

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case type, title, thumbnailUrl, creatorPublicId, userName
        case hashtags, foodName, cookingStyle, rating, recipeTitle, isPrivate
    }
}
