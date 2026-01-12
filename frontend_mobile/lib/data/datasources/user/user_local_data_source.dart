import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:pairing_planet2_frontend/core/utils/cache_utils.dart';
import 'package:pairing_planet2_frontend/core/utils/json_parser.dart';
import 'package:pairing_planet2_frontend/data/models/local/cached_profile.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/user/cooking_dna_dto.dart';

class UserLocalDataSource {
  final Isar _isar;
  static const String _myRecipesKey = 'my_recipes_page_0';
  static const String _myLogsKey = 'my_logs_page_0';
  static const String _savedRecipesKey = 'saved_recipes_page_0';
  static const String _cookingDnaKey = 'cooking_dna';

  UserLocalDataSource(this._isar);

  // ============ My Recipes ============

  Future<void> cacheMyRecipes(List<RecipeSummaryDto> recipes, bool hasNext) async {
    final jsonData = {
      'items': recipes.map((r) => r.toJson()).toList(),
      'hasNext': hasNext,
      'cachedAt': DateTime.now().toIso8601String(),
    };

    await _isar.writeTxn(() async {
      final existing = await _isar.cachedProfiles
          .filter()
          .cacheKeyEqualTo(_myRecipesKey)
          .findFirst();

      final cached = CachedProfile()
        ..cacheKey = _myRecipesKey
        ..jsonData = jsonEncode(jsonData)
        ..cachedAt = DateTime.now()
        ..hasNext = hasNext;

      if (existing != null) {
        cached.id = existing.id;
      }
      await _isar.cachedProfiles.put(cached);
    });
  }

  Future<CachedData<({List<RecipeSummaryDto> items, bool hasNext})>?> getCachedMyRecipes() async {
    final cached = await _isar.cachedProfiles
        .filter()
        .cacheKeyEqualTo(_myRecipesKey)
        .findFirst();

    if (cached == null) return null;

    try {
      // Parse JSON in background isolate to avoid UI thread blocking
      final json = await parseJsonInBackground(cached.jsonData);
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

  Future<void> clearMyRecipesCache() async {
    await _isar.writeTxn(() async {
      await _isar.cachedProfiles
          .filter()
          .cacheKeyEqualTo(_myRecipesKey)
          .deleteAll();
    });
  }

  // ============ My Logs ============

  Future<void> cacheMyLogs(List<LogPostSummaryDto> logs, bool hasNext) async {
    final jsonData = {
      'items': logs.map((l) => l.toJson()).toList(),
      'hasNext': hasNext,
      'cachedAt': DateTime.now().toIso8601String(),
    };

    await _isar.writeTxn(() async {
      final existing = await _isar.cachedProfiles
          .filter()
          .cacheKeyEqualTo(_myLogsKey)
          .findFirst();

      final cached = CachedProfile()
        ..cacheKey = _myLogsKey
        ..jsonData = jsonEncode(jsonData)
        ..cachedAt = DateTime.now()
        ..hasNext = hasNext;

      if (existing != null) {
        cached.id = existing.id;
      }
      await _isar.cachedProfiles.put(cached);
    });
  }

  Future<CachedData<({List<LogPostSummaryDto> items, bool hasNext})>?> getCachedMyLogs() async {
    final cached = await _isar.cachedProfiles
        .filter()
        .cacheKeyEqualTo(_myLogsKey)
        .findFirst();

    if (cached == null) return null;

    try {
      // Parse JSON in background isolate to avoid UI thread blocking
      final json = await parseJsonInBackground(cached.jsonData);
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

  Future<void> clearMyLogsCache() async {
    await _isar.writeTxn(() async {
      await _isar.cachedProfiles
          .filter()
          .cacheKeyEqualTo(_myLogsKey)
          .deleteAll();
    });
  }

  // ============ Saved Recipes ============

  Future<void> cacheSavedRecipes(List<RecipeSummaryDto> recipes, bool hasNext) async {
    final jsonData = {
      'items': recipes.map((r) => r.toJson()).toList(),
      'hasNext': hasNext,
      'cachedAt': DateTime.now().toIso8601String(),
    };

    await _isar.writeTxn(() async {
      final existing = await _isar.cachedProfiles
          .filter()
          .cacheKeyEqualTo(_savedRecipesKey)
          .findFirst();

      final cached = CachedProfile()
        ..cacheKey = _savedRecipesKey
        ..jsonData = jsonEncode(jsonData)
        ..cachedAt = DateTime.now()
        ..hasNext = hasNext;

      if (existing != null) {
        cached.id = existing.id;
      }
      await _isar.cachedProfiles.put(cached);
    });
  }

  Future<CachedData<({List<RecipeSummaryDto> items, bool hasNext})>?> getCachedSavedRecipes() async {
    final cached = await _isar.cachedProfiles
        .filter()
        .cacheKeyEqualTo(_savedRecipesKey)
        .findFirst();

    if (cached == null) return null;

    try {
      // Parse JSON in background isolate to avoid UI thread blocking
      final json = await parseJsonInBackground(cached.jsonData);
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

  Future<void> clearSavedRecipesCache() async {
    await _isar.writeTxn(() async {
      await _isar.cachedProfiles
          .filter()
          .cacheKeyEqualTo(_savedRecipesKey)
          .deleteAll();
    });
  }

  // ============ Cooking DNA ============

  Future<void> cacheCookingDna(CookingDnaDto cookingDna) async {
    final jsonData = {
      'data': cookingDna.toJson(),
      'cachedAt': DateTime.now().toIso8601String(),
    };

    await _isar.writeTxn(() async {
      final existing = await _isar.cachedProfiles
          .filter()
          .cacheKeyEqualTo(_cookingDnaKey)
          .findFirst();

      final cached = CachedProfile()
        ..cacheKey = _cookingDnaKey
        ..jsonData = jsonEncode(jsonData)
        ..cachedAt = DateTime.now()
        ..hasNext = false;

      if (existing != null) {
        cached.id = existing.id;
      }
      await _isar.cachedProfiles.put(cached);
    });
  }

  Future<CachedData<CookingDnaDto>?> getCachedCookingDna() async {
    final cached = await _isar.cachedProfiles
        .filter()
        .cacheKeyEqualTo(_cookingDnaKey)
        .findFirst();

    if (cached == null) return null;

    try {
      final json = jsonDecode(cached.jsonData) as Map<String, dynamic>;
      final data = CookingDnaDto.fromJson(json['data'] as Map<String, dynamic>);
      final cachedAt = DateTime.parse(json['cachedAt'] as String);

      return CachedData(
        data: data,
        cachedAt: cachedAt,
      );
    } catch (e) {
      await clearCookingDnaCache();
      return null;
    }
  }

  Future<void> clearCookingDnaCache() async {
    await _isar.writeTxn(() async {
      await _isar.cachedProfiles
          .filter()
          .cacheKeyEqualTo(_cookingDnaKey)
          .deleteAll();
    });
  }

  // ============ Clear All ============

  Future<void> clearAllCaches() async {
    await _isar.writeTxn(() async {
      await _isar.cachedProfiles.clear();
    });
  }
}
