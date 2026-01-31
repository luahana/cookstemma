package com.cookstemma.app.domain.model

import com.google.gson.annotations.SerializedName

// Recipe Summary - matches API response for list endpoints
data class RecipeSummary(
    @SerializedName("publicId")
    val id: String,
    val title: String,
    val description: String?,
    val foodName: String,
    val cookingStyle: String?,
    val userName: String,
    val thumbnail: String?,
    val variantCount: Int = 0,
    val logCount: Int = 0,
    val servings: Int?,
    val cookingTimeRange: String?,
    @SerializedName("hashtags")
    val hashtagList: List<String> = emptyList(),
    val isPrivate: Boolean = false,
    @SerializedName("isSaved")
    val savedStatus: Boolean? = null
) {
    // Computed properties for compatibility
    val coverImageUrl: String? get() = thumbnail
    val cookCount: Int get() = logCount
    val averageRating: Double? get() = null
    val isSaved: Boolean get() = savedStatus ?: false
    val hashtags: List<String> get() = hashtagList
}

// Recipe Detail - matches API response for detail endpoint
data class RecipeDetail(
    @SerializedName("publicId")
    val id: String,
    val title: String,
    val description: String?,
    val foodName: String,
    val cookingStyle: String?,
    val userName: String,
    val creatorPublicId: String,
    @SerializedName("ingredients")
    val ingredientList: List<Ingredient> = emptyList(),
    @SerializedName("steps")
    val stepList: List<RecipeStep> = emptyList(),
    @SerializedName("hashtags")
    val hashtagObjects: List<HashtagInfo>? = null,
    val servings: Int?,
    val cookingTimeRange: String?,
    @SerializedName("images")
    val recipeImages: List<RecipeImage>? = null,
    val isSavedByCurrentUser: Boolean? = null,
    // UI state (not from API)
    val uiIsSaved: Boolean = false
) {
    // Computed properties for compatibility
    val ingredients: List<Ingredient> get() = ingredientList
    val steps: List<RecipeStep> get() = stepList
    val hashtags: List<String> get() = hashtagObjects?.map { it.name } ?: emptyList()
    val images: List<String> get() = recipeImages?.map { it.imageUrl } ?: emptyList()
    val coverImageUrl: String? get() = recipeImages?.firstOrNull()?.imageUrl
    val author: UserSummary get() = UserSummary(
        id = creatorPublicId,
        username = userName,
        displayName = null,
        avatarUrl = null
    )
    val cookCount: Int get() = 0
    val saveCount: Int get() = 0
    val averageRating: Double? get() = null
    val isSaved: Boolean get() = uiIsSaved
    val category: FoodCategory? get() = null

    // Ingredient groupings
    val mainIngredients: List<Ingredient> get() = ingredientList.filter { it.type == "MAIN" }
    val secondaryIngredients: List<Ingredient> get() = ingredientList.filter { it.type == "SECONDARY" }
    val seasonings: List<Ingredient> get() = ingredientList.filter { it.type == "SEASONING" }

    // Initialize saved state from API
    fun withSavedState(): RecipeDetail = copy(uiIsSaved = isSavedByCurrentUser ?: false)

    // Convert to RecipeSummary for use in CreateLogScreen
    fun toSummary(): RecipeSummary = RecipeSummary(
        id = id,
        title = title,
        description = description,
        foodName = foodName,
        cookingStyle = cookingStyle,
        userName = userName,
        thumbnail = coverImageUrl,
        variantCount = 0,
        logCount = cookCount,
        servings = servings,
        cookingTimeRange = cookingTimeRange,
        hashtagList = hashtags,
        isPrivate = false,
        savedStatus = isSaved
    )
}

// Recipe Image from API
data class RecipeImage(
    val imagePublicId: String,
    val imageUrl: String
)

// Note: HashtagInfo is defined in CookingLog.kt

// Ingredient from API
data class Ingredient(
    val name: String,
    val quantity: Double?,
    val unit: String?,
    val type: String // "MAIN", "SECONDARY", "SEASONING"
) {
    val amount: String get() = quantity?.let {
        if (it == it.toLong().toDouble()) it.toLong().toString()
        else it.toString()
    } ?: ""

    val displayUnit: String get() = when (unit) {
        "ML" -> "ml"
        "L" -> "L"
        "TSP" -> "tsp"
        "TBSP" -> "tbsp"
        "CUP" -> "cup"
        "G" -> "g"
        "KG" -> "kg"
        "PIECE" -> "piece"
        "BUNCH" -> "bunch"
        "PACKAGE" -> "pkg"
        else -> unit?.lowercase() ?: ""
    }

    val category: IngredientCategory get() = when (type) {
        "MAIN" -> IngredientCategory.MAIN
        "SECONDARY" -> IngredientCategory.SECONDARY
        "SEASONING" -> IngredientCategory.SEASONING
        else -> IngredientCategory.MAIN
    }

    /**
     * Format the ingredient amount with unit, converting based on user preference.
     */
    fun formatAmount(preference: MeasurementPreference): String {
        if (quantity == null) return ""
        
        val result = MeasurementConverter.convert(quantity, unit, preference)
        return result?.displayString ?: "$amount $displayUnit".trim()
    }
}

enum class IngredientCategory { MAIN, SECONDARY, SEASONING }

// Recipe Step from API
data class RecipeStep(
    val stepNumber: Int,
    val description: String,
    val imageUrl: String?
) {
    val order: Int get() = stepNumber
    val instruction: String get() = description
    val tipContent: String? get() = null
}

// Cooking Time Range
enum class CookingTimeRange(val value: String, val displayName: String) {
    UNDER_15_MIN("UNDER_15_MIN", "Under 15 min"),
    MIN_15_TO_30("MIN_15_TO_30", "15-30 min"),
    MIN_30_TO_60("MIN_30_TO_60", "30-60 min"),
    HOUR_1_TO_2("HOUR_1_TO_2", "1-2 hours"),
    OVER_2_HOURS("OVER_2_HOURS", "Over 2 hours")
}

// Food Category / Cooking Style
enum class FoodCategory(val code: String, val displayName: String, val flag: String) {
    KOREAN("KR", "Korean", "🇰🇷"),
    JAPANESE("JP", "Japanese", "🇯🇵"),
    CHINESE("CN", "Chinese", "🇨🇳"),
    AMERICAN("US", "American", "🇺🇸"),
    ITALIAN("IT", "Italian", "🇮🇹"),
    FRENCH("FR", "French", "🇫🇷"),
    MEXICAN("MX", "Mexican", "🇲🇽"),
    THAI("TH", "Thai", "🇹🇭"),
    VIETNAMESE("VN", "Vietnamese", "🇻🇳"),
    INDIAN("IN", "Indian", "🇮🇳"),
    SPANISH("ES", "Spanish", "🇪🇸"),
    GREEK("GR", "Greek", "🇬🇷"),
    TURKISH("TR", "Turkish", "🇹🇷"),
    GERMAN("DE", "German", "🇩🇪"),
    BRITISH("GB", "British", "🇬🇧"),
    OTHER("OTHER", "Other", "🌍")
}

enum class RecipeSortBy(val value: String) {
    TRENDING("trending"),
    MOST_COOKED("most_cooked"),
    HIGHEST_RATED("highest_rated"),
    NEWEST("newest")
}

enum class ServingsRange(val displayName: String, val minServings: Int, val maxServings: Int?) {
    ONE_TO_TWO("1-2", 1, 2),
    THREE_TO_FOUR("3-4", 3, 4),
    FIVE_TO_SIX("5-6", 5, 6),
    SEVEN_PLUS("7+", 7, null)
}

data class RecipeFilters(
    val cookingTimeRange: CookingTimeRange? = null,
    val category: String? = null,
    val searchQuery: String? = null,
    val servingsRange: ServingsRange? = null,
    val cookingStyle: String? = null,
    val sortBy: RecipeSortBy = RecipeSortBy.TRENDING
)

// Extension to convert cooking time range string to display text
fun String.cookingTimeDisplayText(): String = when (this) {
    "UNDER_15_MIN" -> "Under 15 min"
    "MIN_15_TO_30" -> "15-30 min"
    "MIN_30_TO_60" -> "30-60 min"
    "HOUR_1_TO_2" -> "1-2 hours"
    "OVER_2_HOURS" -> "Over 2 hours"
    else -> this
}

// Extension to convert cooking style code to display name with flag
fun String.cookingStyleDisplay(): String {
    val flag = this.toFlagEmoji()
    val name = when (this.uppercase()) {
        "KR" -> "Korean"
        "JP" -> "Japanese"
        "CN" -> "Chinese"
        "US" -> "American"
        "IT" -> "Italian"
        "FR" -> "French"
        "MX" -> "Mexican"
        "TH" -> "Thai"
        "VN" -> "Vietnamese"
        "IN" -> "Indian"
        "ES" -> "Spanish"
        "GR" -> "Greek"
        "TR" -> "Turkish"
        "DE" -> "German"
        "GB", "UK" -> "British"
        else -> this
    }
    return "$flag $name"
}

// Extension to convert country code to flag emoji
fun String.toFlagEmoji(): String {
    val code = this.uppercase()
    if (code.length != 2) return "🏳️"
    val base = 0x1F1E6 - 'A'.code
    return code.map { char ->
        String(Character.toChars(base + char.code))
    }.joinToString("")
}
