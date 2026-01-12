import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:pairing_planet2_frontend/data/models/local/recently_viewed_entry.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recently_viewed_recipe_dto.dart';

class RecentlyViewedLocalDataSource {
  final Isar _isar;
  static const int _maxRecentItems = 5;

  RecentlyViewedLocalDataSource(this._isar);

  Future<void> addRecentRecipe(RecentlyViewedRecipeDto recipe) async {
    await _isar.writeTxn(() async {
      await _isar.recentlyViewedEntrys
          .filter()
          .publicIdEqualTo(recipe.publicId)
          .deleteAll();

      final entry = RecentlyViewedEntry()
        ..publicId = recipe.publicId
        ..jsonData = jsonEncode(recipe.toJson())
        ..viewedAt = DateTime.now();

      await _isar.recentlyViewedEntrys.put(entry);

      final allEntries = await _isar.recentlyViewedEntrys
          .where()
          .sortByViewedAtDesc()
          .findAll();

      if (allEntries.length > _maxRecentItems) {
        final entriesToDelete = allEntries.sublist(_maxRecentItems);
        await _isar.recentlyViewedEntrys
            .deleteAll(entriesToDelete.map((e) => e.id).toList());
      }
    });
  }

  Future<List<RecentlyViewedRecipeDto>> getRecentRecipes() async {
    final entries = await _isar.recentlyViewedEntrys
        .where()
        .sortByViewedAtDesc()
        .limit(_maxRecentItems)
        .findAll();

    final recipes = <RecentlyViewedRecipeDto>[];
    for (final entry in entries) {
      try {
        recipes.add(RecentlyViewedRecipeDto.fromJson(
            jsonDecode(entry.jsonData) as Map<String, dynamic>));
      } catch (e) {
        // Skip corrupted entries
      }
    }
    return recipes;
  }

  Future<void> removeRecipe(String publicId) async {
    await _isar.writeTxn(() async {
      await _isar.recentlyViewedEntrys
          .filter()
          .publicIdEqualTo(publicId)
          .deleteAll();
    });
  }

  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.recentlyViewedEntrys.clear();
    });
  }
}
