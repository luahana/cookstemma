import XCTest
@testable import Cookstemma

final class RecipeModelTests: XCTestCase {

    // MARK: - JSONDecoder Setup

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    // MARK: - RecipeSummary Tests

    func testRecipeSummary_parsesFromJSON() throws {
        // Given
        let json = """
        {
            "publicId": "recipe-123",
            "title": "Kimchi Fried Rice",
            "description": "A delicious Korean dish",
            "coverImageUrl": "https://example.com/image.jpg",
            "cookingTimeRange": "BETWEEN_15_AND_30_MIN",
            "servings": 2,
            "cookCount": 156,
            "averageRating": 4.3,
            "author": {
                "publicId": "user-1",
                "username": "chefkim",
                "displayName": "Chef Kim",
                "avatarUrl": "https://example.com/avatar.jpg",
                "level": 24,
                "isFollowing": true
            },
            "isSaved": false,
            "category": {
                "publicId": "cat-1",
                "name": "Korean",
                "iconUrl": "https://example.com/korean.png"
            },
            "createdAt": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        // When
        let recipe = try decoder.decode(RecipeSummary.self, from: json)

        // Then
        XCTAssertEqual(recipe.id, "recipe-123")
        XCTAssertEqual(recipe.title, "Kimchi Fried Rice")
        XCTAssertEqual(recipe.description, "A delicious Korean dish")
        XCTAssertEqual(recipe.coverImageUrl, "https://example.com/image.jpg")
        XCTAssertEqual(recipe.cookingTimeRange, .between15And30)
        XCTAssertEqual(recipe.servings, 2)
        XCTAssertEqual(recipe.cookCount, 156)
        XCTAssertEqual(recipe.averageRating, 4.3)
        XCTAssertEqual(recipe.author.username, "chefkim")
        XCTAssertFalse(recipe.isSaved)
        XCTAssertEqual(recipe.category?.name, "Korean")
    }

    func testRecipeSummary_handlesOptionalFields() throws {
        // Given - minimal required fields
        let json = """
        {
            "publicId": "recipe-123",
            "title": "Simple Recipe",
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
            "createdAt": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        // When
        let recipe = try decoder.decode(RecipeSummary.self, from: json)

        // Then
        XCTAssertEqual(recipe.id, "recipe-123")
        XCTAssertNil(recipe.description)
        XCTAssertNil(recipe.coverImageUrl)
        XCTAssertNil(recipe.cookingTimeRange)
        XCTAssertNil(recipe.servings)
        XCTAssertNil(recipe.averageRating)
        XCTAssertNil(recipe.category)
    }

    // MARK: - RecipeDetail Tests

    func testRecipeDetail_parsesFromJSON() throws {
        // Given
        let json = """
        {
            "publicId": "recipe-123",
            "title": "Kimchi Fried Rice",
            "description": "A delicious Korean dish",
            "images": [
                {
                    "publicId": "img-1",
                    "url": "https://example.com/image1.jpg",
                    "thumbnailUrl": "https://example.com/thumb1.jpg",
                    "width": 800,
                    "height": 600
                }
            ],
            "cookingTimeRange": "BETWEEN_30_AND_60_MIN",
            "servings": 4,
            "cookCount": 156,
            "averageRating": 4.5,
            "author": {
                "publicId": "user-1",
                "username": "chefkim",
                "displayName": "Chef Kim",
                "avatarUrl": null,
                "level": 24,
                "isFollowing": true
            },
            "isSaved": true,
            "ingredients": [
                {
                    "publicId": "ing-1",
                    "name": "Cooked rice",
                    "amount": 2.0,
                    "unit": "CUP",
                    "type": "MAIN",
                    "foodId": null,
                    "note": "Day-old rice works best"
                },
                {
                    "publicId": "ing-2",
                    "name": "Kimchi",
                    "amount": 1.0,
                    "unit": "CUP",
                    "type": "MAIN",
                    "foodId": null,
                    "note": null
                },
                {
                    "publicId": "ing-3",
                    "name": "Green onions",
                    "amount": 2.0,
                    "unit": "PIECE",
                    "type": "SECONDARY",
                    "foodId": null,
                    "note": null
                },
                {
                    "publicId": "ing-4",
                    "name": "Sesame oil",
                    "amount": 1.0,
                    "unit": "TBSP",
                    "type": "SEASONING",
                    "foodId": null,
                    "note": null
                }
            ],
            "steps": [
                {
                    "publicId": "step-1",
                    "stepNumber": 1,
                    "instruction": "Heat oil in a large pan",
                    "imageUrl": null,
                    "duration": 60
                },
                {
                    "publicId": "step-2",
                    "stepNumber": 2,
                    "instruction": "Add kimchi and stir fry for 2 minutes",
                    "imageUrl": "https://example.com/step2.jpg",
                    "duration": 120
                }
            ],
            "hashtags": ["korean", "friedrice", "quickmeal"],
            "recentLogs": [],
            "category": {
                "publicId": "cat-1",
                "name": "Korean",
                "iconUrl": null
            },
            "createdAt": "2024-01-15T10:30:00Z",
            "updatedAt": "2024-01-20T14:00:00Z"
        }
        """.data(using: .utf8)!

        // When
        let recipe = try decoder.decode(RecipeDetail.self, from: json)

        // Then
        XCTAssertEqual(recipe.id, "recipe-123")
        XCTAssertEqual(recipe.title, "Kimchi Fried Rice")
        XCTAssertEqual(recipe.images.count, 1)
        XCTAssertEqual(recipe.cookingTimeRange, .between30And60)
        XCTAssertEqual(recipe.servings, 4)
        XCTAssertEqual(recipe.ingredients.count, 4)
        XCTAssertEqual(recipe.steps.count, 2)
        XCTAssertEqual(recipe.hashtags, ["korean", "friedrice", "quickmeal"])
        XCTAssertTrue(recipe.isSaved)
    }

    func testRecipeDetail_ingredientCategoriesFilterCorrectly() throws {
        // Given
        let json = createRecipeDetailJSON(
            mainIngredients: 2,
            secondaryIngredients: 3,
            seasonings: 4
        )

        // When
        let recipe = try decoder.decode(RecipeDetail.self, from: json)

        // Then
        XCTAssertEqual(recipe.mainIngredients.count, 2)
        XCTAssertEqual(recipe.secondaryIngredients.count, 3)
        XCTAssertEqual(recipe.seasonings.count, 4)

        XCTAssertTrue(recipe.mainIngredients.allSatisfy { $0.type == .main })
        XCTAssertTrue(recipe.secondaryIngredients.allSatisfy { $0.type == .secondary })
        XCTAssertTrue(recipe.seasonings.allSatisfy { $0.type == .seasoning })
    }

    // MARK: - CookingTimeRange Tests

    func testCookingTimeRange_allCasesMap() throws {
        let testCases: [(String, CookingTimeRange)] = [
            ("UNDER_15_MIN", .under15),
            ("BETWEEN_15_AND_30_MIN", .between15And30),
            ("BETWEEN_30_AND_60_MIN", .between30And60),
            ("OVER_60_MIN", .over60)
        ]

        for (jsonValue, expectedCase) in testCases {
            let json = "\"\(jsonValue)\"".data(using: .utf8)!
            let result = try decoder.decode(CookingTimeRange.self, from: json)
            XCTAssertEqual(result, expectedCase)
        }
    }

    func testCookingTimeRange_displayText() {
        XCTAssertEqual(CookingTimeRange.under15.displayText, "< 15 min")
        XCTAssertEqual(CookingTimeRange.between15And30.displayText, "15-30 min")
        XCTAssertEqual(CookingTimeRange.between30And60.displayText, "30-60 min")
        XCTAssertEqual(CookingTimeRange.over60.displayText, "60+ min")
    }

    // MARK: - Ingredient Tests

    func testIngredient_parsesAllFields() throws {
        // Given
        let json = """
        {
            "publicId": "ing-1",
            "name": "Soy sauce",
            "amount": 2.5,
            "unit": "TBSP",
            "type": "SEASONING",
            "foodId": "food-123",
            "note": "Low sodium preferred"
        }
        """.data(using: .utf8)!

        // When
        let ingredient = try decoder.decode(Ingredient.self, from: json)

        // Then
        XCTAssertEqual(ingredient.id, "ing-1")
        XCTAssertEqual(ingredient.name, "Soy sauce")
        XCTAssertEqual(ingredient.amount, 2.5)
        XCTAssertEqual(ingredient.unit, .tbsp)
        XCTAssertEqual(ingredient.type, .seasoning)
        XCTAssertEqual(ingredient.foodId, "food-123")
        XCTAssertEqual(ingredient.note, "Low sodium preferred")
    }

    func testIngredient_handlesNullOptionalFields() throws {
        // Given
        let json = """
        {
            "publicId": "ing-1",
            "name": "Salt",
            "amount": null,
            "unit": null,
            "type": "SEASONING",
            "foodId": null,
            "note": null
        }
        """.data(using: .utf8)!

        // When
        let ingredient = try decoder.decode(Ingredient.self, from: json)

        // Then
        XCTAssertEqual(ingredient.name, "Salt")
        XCTAssertNil(ingredient.amount)
        XCTAssertNil(ingredient.unit)
        XCTAssertNil(ingredient.foodId)
        XCTAssertNil(ingredient.note)
    }

    // MARK: - MeasurementUnit Tests

    func testMeasurementUnit_allCasesParse() throws {
        let testCases: [(String, MeasurementUnit, String)] = [
            ("ML", .ml, "ml"),
            ("L", .l, "L"),
            ("TSP", .tsp, "tsp"),
            ("TBSP", .tbsp, "tbsp"),
            ("CUP", .cup, "cup"),
            ("FL_OZ", .flOz, "fl oz"),
            ("G", .g, "g"),
            ("KG", .kg, "kg"),
            ("OZ", .oz, "oz"),
            ("LB", .lb, "lb"),
            ("PIECE", .piece, "piece"),
            ("PINCH", .pinch, "pinch"),
            ("BUNCH", .bunch, "bunch"),
            ("CLOVE", .clove, "clove")
        ]

        for (jsonValue, expectedUnit, expectedDisplayText) in testCases {
            let json = "\"\(jsonValue)\"".data(using: .utf8)!
            let result = try decoder.decode(MeasurementUnit.self, from: json)
            XCTAssertEqual(result, expectedUnit, "Failed for \(jsonValue)")
            XCTAssertEqual(result.displayText, expectedDisplayText)
        }
    }

    // MARK: - RecipeStep Tests

    func testRecipeStep_parsesFromJSON() throws {
        // Given
        let json = """
        {
            "publicId": "step-1",
            "stepNumber": 3,
            "instruction": "Mix all ingredients together",
            "imageUrl": "https://example.com/step3.jpg",
            "duration": 180
        }
        """.data(using: .utf8)!

        // When
        let step = try decoder.decode(RecipeStep.self, from: json)

        // Then
        XCTAssertEqual(step.id, "step-1")
        XCTAssertEqual(step.stepNumber, 3)
        XCTAssertEqual(step.instruction, "Mix all ingredients together")
        XCTAssertEqual(step.imageUrl, "https://example.com/step3.jpg")
        XCTAssertEqual(step.duration, 180)
    }

    // MARK: - FoodCategory Tests

    func testFoodCategory_parsesFromJSON() throws {
        // Given
        let json = """
        {
            "publicId": "cat-korean",
            "name": "Korean",
            "iconUrl": "https://example.com/icons/korean.png"
        }
        """.data(using: .utf8)!

        // When
        let category = try decoder.decode(FoodCategory.self, from: json)

        // Then
        XCTAssertEqual(category.id, "cat-korean")
        XCTAssertEqual(category.name, "Korean")
        XCTAssertEqual(category.iconUrl, "https://example.com/icons/korean.png")
    }

    // MARK: - RecipeFilters Tests

    func testRecipeFilters_defaultIsEmpty() {
        let filters = RecipeFilters()

        XCTAssertTrue(filters.isEmpty)
        XCTAssertNil(filters.cookingTimeRange)
        XCTAssertNil(filters.category)
        XCTAssertNil(filters.searchQuery)
        XCTAssertEqual(filters.sortBy, .trending)
    }

    func testRecipeFilters_isNotEmptyWithFilter() {
        let filters = RecipeFilters(cookingTimeRange: .under15)

        XCTAssertFalse(filters.isEmpty)
    }

    // MARK: - RecipeSortOption Tests

    func testRecipeSortOption_displayText() {
        XCTAssertEqual(RecipeSortOption.trending.displayText, "Trending")
        XCTAssertEqual(RecipeSortOption.mostCooked.displayText, "Most Cooked")
        XCTAssertEqual(RecipeSortOption.highestRated.displayText, "Highest Rated")
        XCTAssertEqual(RecipeSortOption.newest.displayText, "Newest")
    }

    // MARK: - Helpers

    private func createRecipeDetailJSON(
        mainIngredients: Int,
        secondaryIngredients: Int,
        seasonings: Int
    ) -> Data {
        var ingredients: [[String: Any]] = []

        for i in 0..<mainIngredients {
            ingredients.append([
                "publicId": "main-\(i)",
                "name": "Main \(i)",
                "amount": 1.0,
                "unit": "CUP",
                "type": "MAIN",
                "foodId": NSNull(),
                "note": NSNull()
            ])
        }

        for i in 0..<secondaryIngredients {
            ingredients.append([
                "publicId": "sec-\(i)",
                "name": "Secondary \(i)",
                "amount": 1.0,
                "unit": "PIECE",
                "type": "SECONDARY",
                "foodId": NSNull(),
                "note": NSNull()
            ])
        }

        for i in 0..<seasonings {
            ingredients.append([
                "publicId": "seas-\(i)",
                "name": "Seasoning \(i)",
                "amount": 1.0,
                "unit": "TSP",
                "type": "SEASONING",
                "foodId": NSNull(),
                "note": NSNull()
            ])
        }

        let recipe: [String: Any] = [
            "publicId": "recipe-test",
            "title": "Test Recipe",
            "description": NSNull(),
            "images": [],
            "cookingTimeRange": "UNDER_15_MIN",
            "servings": 2,
            "cookCount": 10,
            "averageRating": 4.0,
            "author": [
                "publicId": "user-1",
                "username": "test",
                "displayName": NSNull(),
                "avatarUrl": NSNull(),
                "level": 1,
                "isFollowing": NSNull()
            ],
            "isSaved": false,
            "ingredients": ingredients,
            "steps": [],
            "hashtags": [],
            "recentLogs": [],
            "category": NSNull(),
            "createdAt": "2024-01-01T00:00:00Z",
            "updatedAt": "2024-01-01T00:00:00Z"
        ]

        return try! JSONSerialization.data(withJSONObject: recipe)
    }
}
