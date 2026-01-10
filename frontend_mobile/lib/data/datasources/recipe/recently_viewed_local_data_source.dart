import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recently_viewed_recipe_dto.dart';

/// Local data source for managing recently viewed recipes using Hive.
class RecentlyViewedLocalDataSource {
  static const String _boxName = 'recently_viewed_box';
  static const String _recentRecipesKey = 'recent_recipes';
  static const int _maxRecentItems = 5;

  /// Add a recipe to recently viewed.
  /// Moves existing recipe to top if already present.
  /// Limits to 5 most recent items.
  Future<void> addRecentRecipe(RecentlyViewedRecipeDto recipe) async {
    final box = await Hive.openBox(_boxName);
    final recipes = await getRecentRecipes();

    // Remove if exists (to move to top)
    recipes.removeWhere((r) => r.publicId == recipe.publicId);

    // Add to front with updated timestamp
    recipes.insert(0, recipe);

    // Trim to max size
    if (recipes.length > _maxRecentItems) {
      recipes.removeRange(_maxRecentItems, recipes.length);
    }

    await box.put(
      _recentRecipesKey,
      jsonEncode(recipes.map((r) => r.toJson()).toList()),
    );
  }

  /// Get recently viewed recipes.
  Future<List<RecentlyViewedRecipeDto>> getRecentRecipes() async {
    final box = await Hive.openBox(_boxName);
    final jsonString = box.get(_recentRecipesKey);

    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) =>
              RecentlyViewedRecipeDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Clear corrupted data
      await box.delete(_recentRecipesKey);
      return [];
    }
  }

  /// Remove a specific recipe from history.
  Future<void> removeRecipe(String publicId) async {
    final box = await Hive.openBox(_boxName);
    final recipes = await getRecentRecipes();
    recipes.removeWhere((r) => r.publicId == publicId);
    await box.put(
      _recentRecipesKey,
      jsonEncode(recipes.map((r) => r.toJson()).toList()),
    );
  }

  /// Clear all recently viewed recipes.
  Future<void> clearAll() async {
    final box = await Hive.openBox(_boxName);
    await box.delete(_recentRecipesKey);
  }
}
