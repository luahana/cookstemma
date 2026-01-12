import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:pairing_planet2_frontend/core/utils/cache_utils.dart';
import 'package:pairing_planet2_frontend/core/utils/json_parser.dart';
import 'package:pairing_planet2_frontend/data/models/local/cached_recipe.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_detail_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';

class RecipeLocalDataSource {
  final Isar _isar;
  static const String _recipeListKey = 'recipe_list_page_0';

  RecipeLocalDataSource(this._isar);

  Future<void> cacheRecipeDetail(RecipeDetailResponseDto recipe) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.cachedRecipes
          .filter()
          .cacheKeyEqualTo(recipe.publicId)
          .findFirst();

      final cached = CachedRecipe()
        ..cacheKey = recipe.publicId
        ..jsonData = jsonEncode(recipe.toJson())
        ..cachedAt = DateTime.now();

      if (existing != null) {
        cached.id = existing.id;
      }
      await _isar.cachedRecipes.put(cached);
    });
  }

  Future<RecipeDetailResponseDto?> getLastRecipeDetail(String publicId) async {
    final cached = await _isar.cachedRecipes
        .filter()
        .cacheKeyEqualTo(publicId)
        .findFirst();

    if (cached != null) {
      try {
        // Parse JSON in background isolate to avoid UI thread blocking
        final json = await parseJsonInBackground(cached.jsonData);
        return RecipeDetailResponseDto.fromJson(json);
      } catch (e) {
        await _isar.writeTxn(() async {
          await _isar.cachedRecipes.delete(cached.id);
        });
        return null;
      }
    }
    return null;
  }

  Future<void> cacheRecipeList(List<RecipeSummaryDto> recipes) async {
    final jsonData = {
      'data': recipes.map((r) => r.toJson()).toList(),
      'cachedAt': DateTime.now().toIso8601String(),
    };

    await _isar.writeTxn(() async {
      final existing = await _isar.cachedRecipes
          .filter()
          .cacheKeyEqualTo(_recipeListKey)
          .findFirst();

      final cached = CachedRecipe()
        ..cacheKey = _recipeListKey
        ..jsonData = jsonEncode(jsonData)
        ..cachedAt = DateTime.now();

      if (existing != null) {
        cached.id = existing.id;
      }
      await _isar.cachedRecipes.put(cached);
    });
  }

  Future<CachedData<List<RecipeSummaryDto>>?> getCachedRecipeList() async {
    final cached = await _isar.cachedRecipes
        .filter()
        .cacheKeyEqualTo(_recipeListKey)
        .findFirst();

    if (cached == null) return null;

    try {
      // Parse JSON in background isolate to avoid UI thread blocking
      final json = await parseJsonInBackground(cached.jsonData);
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
      await _isar.writeTxn(() async {
        await _isar.cachedRecipes.delete(cached.id);
      });
      return null;
    }
  }

  Future<void> clearRecipeListCache() async {
    await _isar.writeTxn(() async {
      await _isar.cachedRecipes
          .filter()
          .cacheKeyEqualTo(_recipeListKey)
          .deleteAll();
    });
  }

  Future<void> removeRecipeDetail(String publicId) async {
    await _isar.writeTxn(() async {
      await _isar.cachedRecipes
          .filter()
          .cacheKeyEqualTo(publicId)
          .deleteAll();
      await _isar.cachedRecipes
          .filter()
          .cacheKeyEqualTo(_recipeListKey)
          .deleteAll();
    });
  }
}
