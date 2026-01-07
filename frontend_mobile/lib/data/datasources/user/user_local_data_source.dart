import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:pairing_planet2_frontend/core/utils/cache_utils.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';

/// Local data source for caching profile tab data using Hive.
class UserLocalDataSource {
  static const String _boxName = 'profile_cache_box';
  static const String _myRecipesKey = 'my_recipes_page_0';
  static const String _myLogsKey = 'my_logs_page_0';
  static const String _savedRecipesKey = 'saved_recipes_page_0';

  // ============ My Recipes ============

  /// Cache my recipes (first page) with current timestamp.
  Future<void> cacheMyRecipes(List<RecipeSummaryDto> recipes, bool hasNext) async {
    final box = await Hive.openBox(_boxName);
    final jsonData = {
      'items': recipes.map((r) => r.toJson()).toList(),
      'hasNext': hasNext,
      'cachedAt': DateTime.now().toIso8601String(),
    };
    await box.put(_myRecipesKey, jsonEncode(jsonData));
  }

  /// Get cached my recipes with timestamp.
  /// Returns null if no cached data exists.
  Future<CachedData<({List<RecipeSummaryDto> items, bool hasNext})>?> getCachedMyRecipes() async {
    final box = await Hive.openBox(_boxName);
    final jsonString = box.get(_myRecipesKey);

    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final itemsJson = json['items'] as List<dynamic>;
      final hasNext = json['hasNext'] as bool;
      final cachedAt = DateTime.parse(json['cachedAt'] as String);

      final items = itemsJson
          .map((item) => RecipeSummaryDto.fromJson(item as Map<String, dynamic>))
          .toList();

      return CachedData(
        data: (items: items, hasNext: hasNext),
        cachedAt: cachedAt,
      );
    } catch (e) {
      await clearMyRecipesCache();
      return null;
    }
  }

  /// Clear cached my recipes.
  Future<void> clearMyRecipesCache() async {
    final box = await Hive.openBox(_boxName);
    await box.delete(_myRecipesKey);
  }

  // ============ My Logs ============

  /// Cache my logs (first page) with current timestamp.
  Future<void> cacheMyLogs(List<LogPostSummaryDto> logs, bool hasNext) async {
    final box = await Hive.openBox(_boxName);
    final jsonData = {
      'items': logs.map((l) => l.toJson()).toList(),
      'hasNext': hasNext,
      'cachedAt': DateTime.now().toIso8601String(),
    };
    await box.put(_myLogsKey, jsonEncode(jsonData));
  }

  /// Get cached my logs with timestamp.
  /// Returns null if no cached data exists.
  Future<CachedData<({List<LogPostSummaryDto> items, bool hasNext})>?> getCachedMyLogs() async {
    final box = await Hive.openBox(_boxName);
    final jsonString = box.get(_myLogsKey);

    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final itemsJson = json['items'] as List<dynamic>;
      final hasNext = json['hasNext'] as bool;
      final cachedAt = DateTime.parse(json['cachedAt'] as String);

      final items = itemsJson
          .map((item) => LogPostSummaryDto.fromJson(item as Map<String, dynamic>))
          .toList();

      return CachedData(
        data: (items: items, hasNext: hasNext),
        cachedAt: cachedAt,
      );
    } catch (e) {
      await clearMyLogsCache();
      return null;
    }
  }

  /// Clear cached my logs.
  Future<void> clearMyLogsCache() async {
    final box = await Hive.openBox(_boxName);
    await box.delete(_myLogsKey);
  }

  // ============ Saved Recipes ============

  /// Cache saved recipes (first page) with current timestamp.
  Future<void> cacheSavedRecipes(List<RecipeSummaryDto> recipes, bool hasNext) async {
    final box = await Hive.openBox(_boxName);
    final jsonData = {
      'items': recipes.map((r) => r.toJson()).toList(),
      'hasNext': hasNext,
      'cachedAt': DateTime.now().toIso8601String(),
    };
    await box.put(_savedRecipesKey, jsonEncode(jsonData));
  }

  /// Get cached saved recipes with timestamp.
  /// Returns null if no cached data exists.
  Future<CachedData<({List<RecipeSummaryDto> items, bool hasNext})>?> getCachedSavedRecipes() async {
    final box = await Hive.openBox(_boxName);
    final jsonString = box.get(_savedRecipesKey);

    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final itemsJson = json['items'] as List<dynamic>;
      final hasNext = json['hasNext'] as bool;
      final cachedAt = DateTime.parse(json['cachedAt'] as String);

      final items = itemsJson
          .map((item) => RecipeSummaryDto.fromJson(item as Map<String, dynamic>))
          .toList();

      return CachedData(
        data: (items: items, hasNext: hasNext),
        cachedAt: cachedAt,
      );
    } catch (e) {
      await clearSavedRecipesCache();
      return null;
    }
  }

  /// Clear cached saved recipes.
  Future<void> clearSavedRecipesCache() async {
    final box = await Hive.openBox(_boxName);
    await box.delete(_savedRecipesKey);
  }

  // ============ Clear All ============

  /// Clear all profile caches (call on logout).
  Future<void> clearAllCaches() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }
}
