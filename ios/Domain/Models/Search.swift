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

// MARK: - Hashtag Count (for trending/search results)

struct HashtagCount: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let postCount: Int

    var displayName: String { "#\(name)" }

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case name, postCount
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
