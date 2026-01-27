import Foundation

// MARK: - Recipe Summary (for list)

struct RecipeSummary: Codable, Identifiable, Equatable {
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

    // Computed properties for compatibility
    var coverImageUrl: String? { thumbnail }
    var cookCount: Int { logCount }
    var averageRating: Double? { nil }
    var isSaved: Bool { false }
}

// MARK: - Recipe Detail

struct RecipeDetail: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?
    let foodName: String
    let cookingStyle: String?
    let userName: String
    let creatorPublicId: String
    let ingredients: [Ingredient]
    let steps: [RecipeStep]
    let hashtagObjects: [HashtagInfo]?
    let servings: Int?
    let cookingTimeRange: String?
    let recipeImages: [RecipeImage]?
    let isSavedByCurrentUser: Bool?

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case title, description, foodName, cookingStyle
        case userName, creatorPublicId, ingredients, steps
        case hashtagObjects = "hashtags"
        case servings, cookingTimeRange
        case recipeImages = "images"
        case isSavedByCurrentUser
    }

    var mainIngredients: [Ingredient] { ingredients.filter { $0.type == "MAIN" } }
    var secondaryIngredients: [Ingredient] { ingredients.filter { $0.type == "SECONDARY" } }
    var seasonings: [Ingredient] { ingredients.filter { $0.type == "SEASONING" } }

    // Computed properties for compatibility
    var hashtags: [String]? {
        hashtagObjects?.map { $0.name }
    }
    var images: [ImageInfo] {
        recipeImages?.map { img in
            ImageInfo(id: img.imagePublicId, url: img.imageUrl, thumbnailUrl: img.imageUrl, width: nil, height: nil)
        } ?? []
    }
    var thumbnail: String? {
        recipeImages?.first?.imageUrl
    }
    var author: UserSummary {
        UserSummary(id: creatorPublicId, username: userName, displayName: nil, avatarUrl: nil, level: 0, isFollowing: nil)
    }
    var cookCount: Int { 0 }
    var averageRating: Double? { nil }
    var isSaved: Bool { isSavedByCurrentUser ?? false }
}

// MARK: - Recipe Image

struct RecipeImage: Codable, Identifiable, Equatable {
    let imagePublicId: String
    let imageUrl: String

    var id: String { imagePublicId }
}

// MARK: - Hashtag Info

struct HashtagInfo: Codable, Identifiable, Equatable {
    let publicId: String
    let name: String

    var id: String { publicId }
}

// MARK: - Ingredient

struct Ingredient: Codable, Identifiable, Equatable {
    var id: String { name }
    let name: String
    let quantity: Double?
    let unit: String?
    let type: String

    var amount: Double? { quantity }

    var displayUnit: String {
        guard let unit = unit else { return "" }
        switch unit {
        case "ML": return "ml"
        case "L": return "L"
        case "TSP": return "tsp"
        case "TBSP": return "tbsp"
        case "CUP": return "cup"
        case "G": return "g"
        case "KG": return "kg"
        case "PIECE": return "piece"
        case "BUNCH": return "bunch"
        case "PACKAGE": return "pkg"
        default: return unit.lowercased()
        }
    }
}

// MARK: - Recipe Step

struct RecipeStep: Codable, Identifiable, Equatable {
    var id: String { "\(stepNumber)" }
    let stepNumber: Int
    let description: String
    let imageUrl: String?

    var instruction: String { description }

    enum CodingKeys: String, CodingKey {
        case stepNumber, description, imageUrl
    }
}

// MARK: - Cooking Time Range Helper

extension String {
    var cookingTimeDisplayText: String {
        switch self {
        case "UNDER_15", "UNDER_15_MIN": return "<15 min"
        case "MIN_15_TO_30": return "15-30 min"
        case "MIN_30_TO_60": return "30-60 min"
        case "HOUR_1_TO_2": return "1-2 hr"
        case "OVER_60": return "60+ min"
        case "OVER_2_HOURS": return "2+ hr"
        default: return self
        }
    }

    /// Converts a country/region code to flag emoji (e.g., "KR" -> "🇰🇷")
    var flagEmoji: String {
        let code = self.uppercased()
        guard code.count == 2 else { return "🏳️" }
        let base: UInt32 = 127397
        var emoji = ""
        for scalar in code.unicodeScalars {
            if let flag = UnicodeScalar(base + scalar.value) {
                emoji.append(String(flag))
            }
        }
        return emoji.isEmpty ? "🏳️" : emoji
    }

    /// Returns the cooking style display name
    var cookingStyleName: String {
        switch self.uppercased() {
        case "KR": return "Korean"
        case "JP": return "Japanese"
        case "CN": return "Chinese"
        case "US": return "American"
        case "IT": return "Italian"
        case "FR": return "French"
        case "MX": return "Mexican"
        case "TH": return "Thai"
        case "VN": return "Vietnamese"
        case "IN": return "Indian"
        case "ES": return "Spanish"
        case "GR": return "Greek"
        case "TR": return "Turkish"
        case "DE": return "German"
        case "GB", "UK": return "British"
        default: return self
        }
    }
}

// MARK: - CookingTimeRange enum (for filters)

enum CookingTimeRange: String, Codable, CaseIterable {
    case under15 = "UNDER_15"
    case between15And30 = "MIN_15_TO_30"
    case between30And60 = "MIN_30_TO_60"
    case over60 = "OVER_60"

    var displayText: String {
        rawValue.cookingTimeDisplayText
    }
}

// MARK: - Food Category

struct FoodCategory: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let iconUrl: String?

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case name, iconUrl
    }
}

// MARK: - Recipe Filters

struct RecipeFilters: Equatable {
    var cookingTimeRange: CookingTimeRange?
    var category: String?
    var searchQuery: String?
    var sortBy: RecipeSortOption = .trending

    var isEmpty: Bool {
        cookingTimeRange == nil && category == nil && searchQuery == nil && sortBy == .trending
    }
}

enum RecipeSortOption: String, CaseIterable {
    case trending = "TRENDING"
    case mostCooked = "MOST_COOKED"
    case highestRated = "HIGHEST_RATED"
    case newest = "NEWEST"

    var displayText: String {
        switch self {
        case .trending: return "Trending"
        case .mostCooked: return "Most Cooked"
        case .highestRated: return "Highest Rated"
        case .newest: return "Newest"
        }
    }
}
