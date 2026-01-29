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
    private let savedStatus: Bool?

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case title, description, foodName, cookingStyle
        case userName, thumbnail, variantCount, logCount
        case servings, cookingTimeRange, hashtags, isPrivate
        case savedStatus = "isSaved"
    }

    // Computed properties for compatibility
    var coverImageUrl: String? { thumbnail }
    var cookCount: Int { logCount }
    var averageRating: Double? { nil }
    var isSaved: Bool { savedStatus ?? false }

    // Memberwise initializer for manual creation
    init(id: String, title: String, description: String?, foodName: String, cookingStyle: String?,
         userName: String, thumbnail: String?, variantCount: Int, logCount: Int, servings: Int?,
         cookingTimeRange: String?, hashtags: [String], isPrivate: Bool, isSaved: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.foodName = foodName
        self.cookingStyle = cookingStyle
        self.userName = userName
        self.thumbnail = thumbnail
        self.variantCount = variantCount
        self.logCount = logCount
        self.servings = servings
        self.cookingTimeRange = cookingTimeRange
        self.hashtags = hashtags
        self.isPrivate = isPrivate
        self.savedStatus = isSaved
    }
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
        case "UNDER_15_MIN": return String(localized: "filter.time.under15min")
        case "MIN_15_TO_30": return String(localized: "filter.time.15to30min")
        case "MIN_30_TO_60": return String(localized: "filter.time.30to60min")
        case "HOUR_1_TO_2": return String(localized: "filter.time.1to2hr")
        case "OVER_2_HOURS": return String(localized: "filter.time.over2hr")
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
        case "BR": return "Brazilian"
        case "ID": return "Indonesian"
        case "MY": return "Malaysian"
        case "PH": return "Filipino"
        case "AU": return "Australian"
        case "CA": return "Canadian"
        case "RU": return "Russian"
        case "PL": return "Polish"
        case "NL": return "Dutch"
        case "SE": return "Swedish"
        case "NO": return "Norwegian"
        case "DK": return "Danish"
        case "FI": return "Finnish"
        case "PT": return "Portuguese"
        case "MA": return "Moroccan"
        case "EG": return "Egyptian"
        case "ET": return "Ethiopian"
        case "NG": return "Nigerian"
        case "ZA": return "South African"
        case "LB": return "Lebanese"
        case "IR": return "Iranian"
        case "IL": return "Israeli"
        case "SA": return "Saudi"
        case "AE": return "Emirati"
        case "PK": return "Pakistani"
        case "BD": return "Bangladeshi"
        case "TW": return "Taiwanese"
        case "SG": return "Singaporean"
        case "NP": return "Nepalese"
        case "LK": return "Sri Lankan"
        case "PE": return "Peruvian"
        case "AR": return "Argentinian"
        case "CO": return "Colombian"
        case "CU": return "Cuban"
        case "JM": return "Jamaican"
        default: return self
        }
    }
}

// MARK: - CookingTimeRange enum (for filters)

enum CookingTimeRange: String, Codable, CaseIterable {
    case under15Min = "UNDER_15_MIN"
    case min15To30 = "MIN_15_TO_30"
    case min30To60 = "MIN_30_TO_60"
    case hour1To2 = "HOUR_1_TO_2"
    case over2Hours = "OVER_2_HOURS"

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
    var minServings: Int?
    var maxServings: Int?
    var cookingStyle: String?  // Country code (e.g., "KR", "JP")

    var isEmpty: Bool {
        cookingTimeRange == nil && category == nil && searchQuery == nil && minServings == nil && maxServings == nil && cookingStyle == nil
    }
}

enum ServingsOption: CaseIterable {
    case oneToTwo
    case threeToFour
    case fiveToSix
    case sevenPlus

    var displayText: String {
        switch self {
        case .oneToTwo: return String(localized: "filter.servings1to2")
        case .threeToFour: return String(localized: "filter.servings3to4")
        case .fiveToSix: return String(localized: "filter.servings5to6")
        case .sevenPlus: return String(localized: "filter.servings7plus")
        }
    }

    var minServings: Int {
        switch self {
        case .oneToTwo: return 1
        case .threeToFour: return 3
        case .fiveToSix: return 5
        case .sevenPlus: return 7
        }
    }

    var maxServings: Int? {
        switch self {
        case .oneToTwo: return 2
        case .threeToFour: return 4
        case .fiveToSix: return 6
        case .sevenPlus: return nil  // No upper limit
        }
    }
}

// All country codes for cooking style (ISO 3166-1 alpha-2)
enum CookingStyleOption: String, CaseIterable, Identifiable {
    // Popular cuisines first
    case korean = "KR"
    case japanese = "JP"
    case chinese = "CN"
    case american = "US"
    case italian = "IT"
    case french = "FR"
    case mexican = "MX"
    case thai = "TH"
    case vietnamese = "VN"
    case indian = "IN"
    case spanish = "ES"
    case greek = "GR"
    case turkish = "TR"
    case german = "DE"
    case british = "GB"
    case brazilian = "BR"
    case indonesian = "ID"
    case malaysian = "MY"
    case filipino = "PH"
    case australian = "AU"
    case canadian = "CA"
    case russian = "RU"
    case polish = "PL"
    case dutch = "NL"
    case swedish = "SE"
    case norwegian = "NO"
    case danish = "DK"
    case finnish = "FI"
    case portuguese = "PT"
    case moroccan = "MA"
    case egyptian = "EG"
    case ethiopian = "ET"
    case nigerian = "NG"
    case southAfrican = "ZA"
    case lebanese = "LB"
    case iranian = "IR"
    case israeli = "IL"
    case saudi = "SA"
    case emirati = "AE"
    case pakistani = "PK"
    case bangladeshi = "BD"
    case taiwanese = "TW"
    case singaporean = "SG"
    case nepalese = "NP"
    case sriLankan = "LK"
    case peruvian = "PE"
    case argentinian = "AR"
    case colombian = "CO"
    case cuban = "CU"
    case jamaican = "JM"

    var id: String { rawValue }

    var displayText: String {
        rawValue.cookingStyleName
    }

    var flag: String {
        rawValue.flagEmoji
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
