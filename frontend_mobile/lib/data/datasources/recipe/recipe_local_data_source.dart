import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:pairing_planet2_frontend/core/utils/cache_utils.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_detail_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';

class RecipeLocalDataSource {
  static const String _recipeBoxName = 'recipe_box';
  static const String _recipeListKey = 'recipe_list_page_0';

  Future<void> cacheRecipeDetail(RecipeDetailResponseDto recipe) async {
    final box = await Hive.openBox(_recipeBoxName);
    await box.put(recipe.publicId, jsonEncode(recipe.toJson()));
  }

  Future<RecipeDetailResponseDto?> getLastRecipeDetail(String publicId) async {
    final box = await Hive.openBox(_recipeBoxName);
    final jsonString = box.get(publicId);

    if (jsonString != null) {
      return RecipeDetailResponseDto.fromJson(jsonDecode(jsonString));
    }
    return null;
  }

  /// Cache the first page of the recipe list with timestamp.
  Future<void> cacheRecipeList(List<RecipeSummaryDto> recipes) async {
    final box = await Hive.openBox(_recipeBoxName);
    final jsonData = {
      'data': recipes.map((r) => r.toJson()).toList(),
      'cachedAt': DateTime.now().toIso8601String(),
    };
    await box.put(_recipeListKey, jsonEncode(jsonData));
  }

  /// Get cached recipe list with timestamp.
  /// Returns null if no cached data exists.
  Future<CachedData<List<RecipeSummaryDto>>?> getCachedRecipeList() async {
    final box = await Hive.openBox(_recipeBoxName);
    final jsonString = box.get(_recipeListKey);

    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final recipesJson = json['data'] as List<dynamic>;
      final cachedAt = DateTime.parse(json['cachedAt'] as String);

      final recipes = recipesJson
          .map((r) => RecipeSummaryDto.fromJson(r as Map<String, dynamic>))
          .toList();

      return CachedData(
        data: recipes,
        cachedAt: cachedAt,
      );
    } catch (e) {
      // If deserialization fails, clear the corrupted cache entry
      await box.delete(_recipeListKey);
      return null;
    }
  }

  /// Clear the cached recipe list.
  Future<void> clearRecipeListCache() async {
    final box = await Hive.openBox(_recipeBoxName);
    await box.delete(_recipeListKey);
  }

  /// Remove a cached recipe detail (used when deleting a recipe).
  Future<void> removeRecipeDetail(String publicId) async {
    final box = await Hive.openBox(_recipeBoxName);
    await box.delete(publicId);
    // Also clear the recipe list cache since it may contain the deleted recipe
    await clearRecipeListCache();
  }
}
