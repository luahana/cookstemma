import 'dart:math';

import 'package:isar/isar.dart';
import 'package:pairing_planet2_frontend/data/datasources/home/home_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/recipe/recipe_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/hashtag/hashtag_dto.dart';
import 'package:pairing_planet2_frontend/data/models/home/home_feed_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/home/recent_activity_dto.dart';
import 'package:pairing_planet2_frontend/data/models/local/cached_home_feed.dart';
import 'package:pairing_planet2_frontend/data/models/local/cached_log_post.dart';
import 'package:pairing_planet2_frontend/data/models/local/cached_recipe.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/ingredient_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_detail_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/step_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/trending_tree_dto.dart';

final _random = Random(42); // Fixed seed for reproducibility

/// Clears all recipe/log data and seeds with fresh data:
/// - 10 root recipes
/// - 20 variant recipes
/// - 20 log posts
/// - Home feed data
Future<void> seedAllData({
  required Isar isar,
  required RecipeLocalDataSource recipeLocalDataSource,
  required HomeLocalDataSource homeLocalDataSource,
}) async {
  // 1. Clear all existing data
  await isar.writeTxn(() async {
    await isar.cachedRecipes.clear();
    await isar.cachedLogPosts.clear();
    await isar.cachedHomeFeeds.clear();
  });

  // 2. Generate data
  final rootRecipes = _generateRootRecipes();
  final variantRecipes = _generateVariantRecipes(rootRecipes);
  final allRecipes = [...rootRecipes, ...variantRecipes];

  // 3. Cache individual recipe details
  for (final recipe in allRecipes) {
    await recipeLocalDataSource.cacheRecipeDetail(recipe);
  }

  // 4. Cache recipe list (for browse page)
  final summaries = allRecipes.map((r) => _toSummary(r)).toList();
  await recipeLocalDataSource.cacheRecipeList(summaries);

  // 5. Generate and cache home feed
  final recentActivities = _generateRecentActivities(allRecipes);
  final trendingTrees = _generateTrendingTrees(rootRecipes);

  await homeLocalDataSource.cacheHomeFeed(HomeFeedResponseDto(
    recentActivity: recentActivities,
    recentRecipes: summaries.take(5).toList(),
    trendingTrees: trendingTrees,
  ));
}

RecipeSummaryDto _toSummary(RecipeDetailResponseDto r) {
  return RecipeSummaryDto(
    publicId: r.publicId,
    foodName: r.foodName,
    foodMasterPublicId: r.foodMasterPublicId,
    title: r.title,
    description: r.description,
    culinaryLocale: r.culinaryLocale,
    creatorPublicId: r.creatorPublicId,
    creatorName: r.creatorName,
    variantCount: r.variants?.length ?? 0,
    logCount: r.logs?.length ?? 0,
    servings: r.servings,
    cookingTimeRange: r.cookingTimeRange,
    hashtags: r.hashtags?.map((h) => h.name).toList(),
    parentPublicId: r.parentInfo?.publicId,
    rootPublicId: r.rootInfo?.publicId,
    rootTitle: r.rootInfo?.title,
  );
}

// ============================================================
// ROOT RECIPES (10)
// ============================================================

List<RecipeDetailResponseDto> _generateRootRecipes() {
  return [
    _createRootRecipe(
      id: '001',
      foodName: 'Kimchi Fried Rice',
      title: 'Classic Kimchi Fried Rice',
      description: 'A quick and flavorful Korean fried rice with aged kimchi.',
      locale: 'ko-KR',
      servings: 2,
      time: 'MIN_15_TO_30',
      ingredients: [
        _ing('Cooked rice', 2, MeasurementUnit.cup, IngredientType.main),
        _ing('Aged kimchi', 1, MeasurementUnit.cup, IngredientType.main),
        _ing('Pork belly', 100, MeasurementUnit.g, IngredientType.main),
        _ing('Green onion', 2, MeasurementUnit.piece, IngredientType.secondary),
        _ing('Egg', 2, MeasurementUnit.piece, IngredientType.secondary),
        _ing('Sesame oil', 1, MeasurementUnit.tbsp, IngredientType.seasoning),
        _ing('Gochugaru', 1, MeasurementUnit.tsp, IngredientType.seasoning),
      ],
      steps: [
        'Dice pork belly and chop kimchi into small pieces',
        'Heat sesame oil and cook pork until crispy',
        'Add kimchi and stir-fry for 3-4 minutes',
        'Add rice and mix well, season with gochugaru',
        'Fry eggs sunny-side up and serve on top',
      ],
      hashtags: ['Korean', 'Quick', 'ComfortFood'],
    ),
    _createRootRecipe(
      id: '002',
      foodName: 'Beef Bulgogi',
      title: 'Traditional Beef Bulgogi',
      description: 'Thinly sliced beef marinated in sweet soy sauce.',
      locale: 'ko-KR',
      servings: 4,
      time: 'MIN_30_TO_60',
      ingredients: [
        _ing('Beef sirloin', 500, MeasurementUnit.g, IngredientType.main),
        _ing('Asian pear', 0.5, MeasurementUnit.piece, IngredientType.main),
        _ing('Onion', 1, MeasurementUnit.piece, IngredientType.secondary),
        _ing('Green onion', 3, MeasurementUnit.piece, IngredientType.secondary),
        _ing('Soy sauce', 4, MeasurementUnit.tbsp, IngredientType.seasoning),
        _ing('Sugar', 2, MeasurementUnit.tbsp, IngredientType.seasoning),
        _ing('Garlic', 5, MeasurementUnit.clove, IngredientType.seasoning),
        _ing('Sesame oil', 2, MeasurementUnit.tbsp, IngredientType.seasoning),
      ],
      steps: [
        'Slice beef thinly against the grain',
        'Blend pear, onion, and garlic for marinade',
        'Mix with soy sauce, sugar, and sesame oil',
        'Marinate beef for at least 30 minutes',
        'Grill over high heat until caramelized',
      ],
      hashtags: ['Korean', 'BBQ', 'Beef', 'Grilled'],
    ),
    _createRootRecipe(
      id: '003',
      foodName: 'Spaghetti Carbonara',
      title: 'Authentic Roman Carbonara',
      description: 'Creamy pasta with eggs, pecorino, and guanciale.',
      locale: 'en-US',
      servings: 2,
      time: 'MIN_30_TO_60',
      ingredients: [
        _ing('Spaghetti', 200, MeasurementUnit.g, IngredientType.main),
        _ing('Guanciale', 150, MeasurementUnit.g, IngredientType.main),
        _ing('Egg yolks', 4, MeasurementUnit.piece, IngredientType.main),
        _ing('Pecorino Romano', 100, MeasurementUnit.g, IngredientType.secondary),
        _ing('Black pepper', 2, MeasurementUnit.tsp, IngredientType.seasoning),
        _ing('Salt', 1, MeasurementUnit.pinch, IngredientType.seasoning),
      ],
      steps: [
        'Cook guanciale until crispy',
        'Boil spaghetti in salted water until al dente',
        'Whisk egg yolks with pecorino and pepper',
        'Toss hot pasta with guanciale off heat',
        'Add egg mixture and toss vigorously',
      ],
      hashtags: ['Italian', 'Pasta', 'Classic'],
    ),
    _createRootRecipe(
      id: '004',
      foodName: 'Chicken Teriyaki',
      title: 'Glazed Chicken Teriyaki',
      description: 'Juicy chicken with homemade teriyaki glaze.',
      locale: 'en-US',
      servings: 4,
      time: 'MIN_30_TO_60',
      ingredients: [
        _ing('Chicken thighs', 600, MeasurementUnit.g, IngredientType.main),
        _ing('Steamed rice', 2, MeasurementUnit.cup, IngredientType.secondary),
        _ing('Broccoli', 200, MeasurementUnit.g, IngredientType.secondary),
        _ing('Soy sauce', 4, MeasurementUnit.tbsp, IngredientType.seasoning),
        _ing('Mirin', 3, MeasurementUnit.tbsp, IngredientType.seasoning),
        _ing('Sugar', 2, MeasurementUnit.tbsp, IngredientType.seasoning),
        _ing('Ginger', 1, MeasurementUnit.tsp, IngredientType.seasoning),
      ],
      steps: [
        'Mix soy sauce, mirin, sugar, and ginger',
        'Pan-fry chicken skin-side down until golden',
        'Flip and cook until almost done',
        'Add sauce and simmer until thickened',
        'Slice and serve over rice with broccoli',
      ],
      hashtags: ['Japanese', 'Chicken', 'Weeknight'],
    ),
    _createRootRecipe(
      id: '005',
      foodName: 'Doenjang Jjigae',
      title: 'Hearty Doenjang Jjigae',
      description: 'Korean fermented soybean paste stew with tofu.',
      locale: 'ko-KR',
      servings: 4,
      time: 'MIN_30_TO_60',
      ingredients: [
        _ing('Firm tofu', 300, MeasurementUnit.g, IngredientType.main),
        _ing('Zucchini', 1, MeasurementUnit.piece, IngredientType.main),
        _ing('Potato', 1, MeasurementUnit.piece, IngredientType.main),
        _ing('Anchovy stock', 3, MeasurementUnit.cup, IngredientType.secondary),
        _ing('Green chili', 2, MeasurementUnit.piece, IngredientType.secondary),
        _ing('Doenjang', 3, MeasurementUnit.tbsp, IngredientType.seasoning),
        _ing('Garlic', 3, MeasurementUnit.clove, IngredientType.seasoning),
        _ing('Gochugaru', 1, MeasurementUnit.tsp, IngredientType.seasoning),
      ],
      steps: [
        'Cube tofu and dice vegetables',
        'Bring anchovy stock to boil',
        'Dissolve doenjang in stock, add potato',
        'Add tofu, zucchini, and seasonings',
        'Simmer and serve bubbling hot',
      ],
      hashtags: ['Korean', 'Stew', 'Vegetarian', 'ComfortFood'],
    ),
    _createRootRecipe(
      id: '006',
      foodName: 'Caesar Salad',
      title: 'Classic Caesar Salad',
      description: 'Crisp romaine with homemade Caesar dressing.',
      locale: 'en-US',
      servings: 2,
      time: 'MIN_15_TO_30',
      ingredients: [
        _ing('Romaine lettuce', 2, MeasurementUnit.piece, IngredientType.main),
        _ing('Bread cubes', 2, MeasurementUnit.cup, IngredientType.secondary),
        _ing('Parmesan', 50, MeasurementUnit.g, IngredientType.secondary),
        _ing('Egg yolk', 1, MeasurementUnit.piece, IngredientType.seasoning),
        _ing('Anchovy paste', 1, MeasurementUnit.tsp, IngredientType.seasoning),
        _ing('Lemon juice', 2, MeasurementUnit.tbsp, IngredientType.seasoning),
        _ing('Olive oil', 0.5, MeasurementUnit.cup, IngredientType.seasoning),
      ],
      steps: [
        'Toast bread cubes with olive oil and garlic',
        'Mash garlic and anchovy, whisk in egg yolk',
        'Slowly drizzle in oil to emulsify',
        'Tear romaine and toss with dressing',
        'Top with croutons and shaved parmesan',
      ],
      hashtags: ['Salad', 'Quick', 'Classic'],
    ),
    _createRootRecipe(
      id: '007',
      foodName: 'Japchae',
      title: 'Festive Japchae',
      description: 'Korean glass noodles with colorful vegetables.',
      locale: 'ko-KR',
      servings: 6,
      time: 'HOUR_1_PLUS',
      ingredients: [
        _ing('Sweet potato noodles', 250, MeasurementUnit.g, IngredientType.main),
        _ing('Beef sirloin', 150, MeasurementUnit.g, IngredientType.main),
        _ing('Spinach', 200, MeasurementUnit.g, IngredientType.secondary),
        _ing('Carrots', 1, MeasurementUnit.piece, IngredientType.secondary),
        _ing('Shiitake', 5, MeasurementUnit.piece, IngredientType.secondary),
        _ing('Soy sauce', 5, MeasurementUnit.tbsp, IngredientType.seasoning),
        _ing('Sugar', 3, MeasurementUnit.tbsp, IngredientType.seasoning),
        _ing('Sesame oil', 3, MeasurementUnit.tbsp, IngredientType.seasoning),
      ],
      steps: [
        'Soak and cook glass noodles',
        'Blanch spinach and season',
        'Julienne and stir-fry vegetables separately',
        'Marinate and cook beef strips',
        'Combine all and toss with sesame oil',
      ],
      hashtags: ['Korean', 'Noodles', 'Festive', 'PartyFood'],
    ),
    _createRootRecipe(
      id: '008',
      foodName: 'Margherita Pizza',
      title: 'Neapolitan Margherita',
      description: 'Classic pizza with tomatoes, mozzarella, and basil.',
      locale: 'en-US',
      servings: 4,
      time: 'HOUR_1_PLUS',
      ingredients: [
        _ing('Pizza dough', 500, MeasurementUnit.g, IngredientType.main),
        _ing('Fresh mozzarella', 250, MeasurementUnit.g, IngredientType.main),
        _ing('San Marzano tomatoes', 1, MeasurementUnit.can, IngredientType.main),
        _ing('Fresh basil', 1, MeasurementUnit.bunch, IngredientType.secondary),
        _ing('Olive oil', 3, MeasurementUnit.tbsp, IngredientType.seasoning),
        _ing('Salt', 1, MeasurementUnit.tsp, IngredientType.seasoning),
      ],
      steps: [
        'Preheat oven to highest setting',
        'Crush tomatoes with salt and oil',
        'Stretch dough into 12-inch circle',
        'Spread sauce and add mozzarella',
        'Bake until charred, top with basil',
      ],
      hashtags: ['Italian', 'Pizza', 'Vegetarian'],
    ),
    _createRootRecipe(
      id: '009',
      foodName: 'Bibimbap',
      title: 'Colorful Bibimbap',
      description: 'Korean mixed rice bowl with vegetables and gochujang.',
      locale: 'ko-KR',
      servings: 2,
      time: 'MIN_30_TO_60',
      ingredients: [
        _ing('Steamed rice', 2, MeasurementUnit.cup, IngredientType.main),
        _ing('Ground beef', 150, MeasurementUnit.g, IngredientType.main),
        _ing('Spinach', 100, MeasurementUnit.g, IngredientType.secondary),
        _ing('Bean sprouts', 100, MeasurementUnit.g, IngredientType.secondary),
        _ing('Zucchini', 0.5, MeasurementUnit.piece, IngredientType.secondary),
        _ing('Carrots', 0.5, MeasurementUnit.piece, IngredientType.secondary),
        _ing('Egg', 2, MeasurementUnit.piece, IngredientType.secondary),
        _ing('Gochujang', 2, MeasurementUnit.tbsp, IngredientType.seasoning),
        _ing('Sesame oil', 2, MeasurementUnit.tbsp, IngredientType.seasoning),
      ],
      steps: [
        'Prepare each vegetable separately',
        'Season vegetables with sesame oil',
        'Cook beef with soy sauce',
        'Fry eggs sunny-side up',
        'Arrange on rice, serve with gochujang',
      ],
      hashtags: ['Korean', 'Rice', 'Healthy', 'Colorful'],
    ),
    _createRootRecipe(
      id: '010',
      foodName: 'Thai Green Curry',
      title: 'Aromatic Green Curry',
      description: 'Creamy coconut curry with chicken and Thai basil.',
      locale: 'en-US',
      servings: 4,
      time: 'MIN_30_TO_60',
      ingredients: [
        _ing('Chicken breast', 400, MeasurementUnit.g, IngredientType.main),
        _ing('Coconut milk', 400, MeasurementUnit.ml, IngredientType.main),
        _ing('Thai eggplant', 4, MeasurementUnit.piece, IngredientType.secondary),
        _ing('Thai basil', 1, MeasurementUnit.cup, IngredientType.secondary),
        _ing('Bamboo shoots', 100, MeasurementUnit.g, IngredientType.secondary),
        _ing('Green curry paste', 3, MeasurementUnit.tbsp, IngredientType.seasoning),
        _ing('Fish sauce', 2, MeasurementUnit.tbsp, IngredientType.seasoning),
        _ing('Palm sugar', 1, MeasurementUnit.tbsp, IngredientType.seasoning),
      ],
      steps: [
        'Slice chicken into bite-sized pieces',
        'Fry curry paste in coconut cream',
        'Add chicken and cook until done',
        'Pour in coconut milk, add vegetables',
        'Season and stir in Thai basil',
      ],
      hashtags: ['Thai', 'Curry', 'Spicy', 'Coconut'],
    ),
  ];
}

// ============================================================
// VARIANT RECIPES (20)
// ============================================================

List<RecipeDetailResponseDto> _generateVariantRecipes(
    List<RecipeDetailResponseDto> roots) {
  final variants = <RecipeDetailResponseDto>[];
  final variantData = [
    // Variants of Kimchi Fried Rice (001)
    ('001', 'Spam Kimchi Fried Rice', 'With crispy spam cubes', ['INGREDIENT_SUBSTITUTION']),
    ('001', 'Vegetarian Kimchi Bokkeumbap', 'No meat, extra veggies', ['INGREDIENT_REMOVAL']),
    // Variants of Bulgogi (002)
    ('002', 'Spicy Bulgogi', 'Extra gochugaru kick', ['SEASONING_ADJUSTMENT']),
    ('002', 'Chicken Bulgogi', 'Using chicken thighs', ['INGREDIENT_SUBSTITUTION']),
    // Variants of Carbonara (003)
    ('003', 'Bacon Carbonara', 'With crispy bacon', ['INGREDIENT_SUBSTITUTION']),
    ('003', 'Mushroom Carbonara', 'Added cremini mushrooms', ['INGREDIENT_ADDITION']),
    // Variants of Teriyaki (004)
    ('004', 'Salmon Teriyaki', 'With fresh salmon', ['INGREDIENT_SUBSTITUTION']),
    ('004', 'Tofu Teriyaki', 'Vegetarian version', ['INGREDIENT_SUBSTITUTION']),
    // Variants of Doenjang Jjigae (005)
    ('005', 'Seafood Doenjang Jjigae', 'With clams and shrimp', ['INGREDIENT_ADDITION']),
    ('005', 'Mushroom Doenjang Jjigae', 'Extra mushroom varieties', ['INGREDIENT_SUBSTITUTION']),
    // Variants of Caesar Salad (006)
    ('006', 'Chicken Caesar Salad', 'With grilled chicken', ['INGREDIENT_ADDITION']),
    ('006', 'Kale Caesar Salad', 'Using kale instead', ['INGREDIENT_SUBSTITUTION']),
    // Variants of Japchae (007)
    ('007', 'Seafood Japchae', 'With squid and shrimp', ['INGREDIENT_SUBSTITUTION']),
    ('007', 'Vegetable Japchae', 'No meat version', ['INGREDIENT_REMOVAL']),
    // Variants of Pizza (008)
    ('008', 'Pepperoni Margherita', 'Added pepperoni', ['INGREDIENT_ADDITION']),
    ('008', 'Four Cheese Pizza', 'Multiple cheese blend', ['INGREDIENT_SUBSTITUTION']),
    // Variants of Bibimbap (009)
    ('009', 'Dolsot Bibimbap', 'In hot stone pot', ['TECHNIQUE_CHANGE']),
    ('009', 'Salmon Bibimbap', 'With fresh salmon', ['INGREDIENT_SUBSTITUTION']),
    // Variants of Green Curry (010)
    ('010', 'Shrimp Green Curry', 'With prawns', ['INGREDIENT_SUBSTITUTION']),
    ('010', 'Vegetable Green Curry', 'Tofu and vegetables', ['INGREDIENT_SUBSTITUTION']),
  ];

  for (var i = 0; i < variantData.length; i++) {
    final (rootId, title, desc, categories) = variantData[i];
    final root = roots.firstWhere((r) => r.publicId == 'seed-recipe-$rootId');

    variants.add(RecipeDetailResponseDto(
      publicId: 'seed-variant-${(i + 1).toString().padLeft(3, '0')}',
      foodName: root.foodName,
      foodMasterPublicId: root.foodMasterPublicId,
      creatorPublicId: 'seed-user-00${(i % 3) + 1}',
      creatorName: ['Chef Kim', 'Chef Marco', 'Chef Tanaka'][i % 3],
      title: title,
      description: desc,
      culinaryLocale: root.culinaryLocale,
      servings: root.servings,
      cookingTimeRange: root.cookingTimeRange,
      ingredients: root.ingredients,
      steps: root.steps,
      hashtags: root.hashtags,
      changeCategories: categories,
      rootInfo: RecipeSummaryDto(
        publicId: root.publicId,
        foodName: root.foodName,
        foodMasterPublicId: root.foodMasterPublicId,
        title: root.title,
        creatorName: root.creatorName,
      ),
      parentInfo: RecipeSummaryDto(
        publicId: root.publicId,
        foodName: root.foodName,
        foodMasterPublicId: root.foodMasterPublicId,
        title: root.title,
        creatorName: root.creatorName,
      ),
    ));
  }

  return variants;
}

// ============================================================
// LOG POSTS / RECENT ACTIVITY (20)
// ============================================================

List<RecentActivityDto> _generateRecentActivities(
    List<RecipeDetailResponseDto> recipes) {
  final outcomes = ['SUCCESS', 'SUCCESS', 'SUCCESS', 'PARTIAL', 'FAILED'];
  final creators = ['FoodLover', 'HomeCook', 'ChefAmy', 'TastyBites', 'KitchenPro'];
  final activities = <RecentActivityDto>[];

  for (var i = 0; i < 20; i++) {
    final recipe = recipes[i % recipes.length];
    final outcome = outcomes[_random.nextInt(outcomes.length)];
    final creator = creators[_random.nextInt(creators.length)];

    activities.add(RecentActivityDto(
      logPublicId: 'seed-log-${(i + 1).toString().padLeft(3, '0')}',
      outcome: outcome,
      thumbnailUrl: 'https://picsum.photos/seed/${i + 100}/400/400',
      creatorName: creator,
      recipeTitle: recipe.title,
      recipePublicId: recipe.publicId,
      foodName: recipe.foodName,
      createdAt: DateTime.now().subtract(Duration(hours: i * 3)),
      hashtags: recipe.hashtags?.map((h) => h.name).take(3).toList(),
    ));
  }

  return activities;
}

// ============================================================
// TRENDING TREES
// ============================================================

List<TrendingTreeDto> _generateTrendingTrees(
    List<RecipeDetailResponseDto> roots) {
  return roots.take(5).map((r) {
    return TrendingTreeDto(
      rootRecipeId: r.publicId,
      title: r.title,
      foodName: r.foodName,
      culinaryLocale: r.culinaryLocale ?? 'en-US',
      thumbnail: 'https://picsum.photos/seed/${r.publicId}/400/400',
      variantCount: _random.nextInt(10) + 2,
      logCount: _random.nextInt(20) + 5,
      latestChangeSummary: 'New spicy variation added',
    );
  }).toList();
}

// ============================================================
// HELPERS
// ============================================================

RecipeDetailResponseDto _createRootRecipe({
  required String id,
  required String foodName,
  required String title,
  required String description,
  required String locale,
  required int servings,
  required String time,
  required List<IngredientDto> ingredients,
  required List<String> steps,
  required List<String> hashtags,
}) {
  return RecipeDetailResponseDto(
    publicId: 'seed-recipe-$id',
    foodName: foodName,
    foodMasterPublicId: 'food-master-$id',
    creatorPublicId: 'seed-user-001',
    creatorName: 'Chef ${['Kim', 'Marco', 'Tanaka'][int.parse(id) % 3]}',
    title: title,
    description: description,
    culinaryLocale: locale,
    servings: servings,
    cookingTimeRange: time,
    ingredients: ingredients,
    steps: steps
        .asMap()
        .entries
        .map((e) => StepDto(stepNumber: e.key + 1, description: e.value))
        .toList(),
    hashtags: hashtags
        .map((h) => HashtagDto(publicId: 'tag-${h.toLowerCase()}', name: h))
        .toList(),
  );
}

IngredientDto _ing(
    String name, double qty, MeasurementUnit unit, IngredientType type) {
  return IngredientDto(name: name, quantity: qty, unit: unit, type: type);
}
