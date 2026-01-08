import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_draft_dto.dart';

class RecipeDraftLocalDataSource {
  static const String _draftBoxName = 'recipe_draft_box';
  static const String _draftKey = 'current_draft';
  static const int _draftTtlDays = 7;

  /// Save a recipe draft to local storage.
  Future<void> saveDraft(RecipeDraftDto draft) async {
    final box = await Hive.openBox(_draftBoxName);
    final jsonData = {
      'data': draft.toJson(),
      'cachedAt': DateTime.now().toIso8601String(),
    };
    await box.put(_draftKey, jsonEncode(jsonData));
  }

  /// Get the saved draft if it exists and hasn't expired.
  /// Returns null if no draft exists or if it's older than 7 days.
  Future<RecipeDraftDto?> getDraft() async {
    final box = await Hive.openBox(_draftBoxName);
    final jsonString = box.get(_draftKey);

    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(json['cachedAt'] as String);

      // Check 7-day expiration
      if (DateTime.now().difference(cachedAt).inDays > _draftTtlDays) {
        await clearDraft();
        return null;
      }

      return RecipeDraftDto.fromJson(json['data'] as Map<String, dynamic>);
    } catch (e) {
      // If deserialization fails, clear the corrupted cache entry
      await box.delete(_draftKey);
      return null;
    }
  }

  /// Check if a draft exists without loading it.
  Future<bool> hasDraft() async {
    final box = await Hive.openBox(_draftBoxName);
    final jsonString = box.get(_draftKey);

    if (jsonString == null) return false;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(json['cachedAt'] as String);

      // Check 7-day expiration
      if (DateTime.now().difference(cachedAt).inDays > _draftTtlDays) {
        await clearDraft();
        return false;
      }

      return true;
    } catch (e) {
      await box.delete(_draftKey);
      return false;
    }
  }

  /// Clear the saved draft.
  Future<void> clearDraft() async {
    final box = await Hive.openBox(_draftBoxName);
    await box.delete(_draftKey);
  }

  /// Get the timestamp when the draft was last saved.
  Future<DateTime?> getDraftSavedAt() async {
    final box = await Hive.openBox(_draftBoxName);
    final jsonString = box.get(_draftKey);

    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return DateTime.parse(json['cachedAt'] as String);
    } catch (e) {
      return null;
    }
  }
}
