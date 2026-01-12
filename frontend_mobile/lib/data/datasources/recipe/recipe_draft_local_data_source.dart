import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:pairing_planet2_frontend/data/models/local/recipe_draft_entry.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_draft_dto.dart';

class RecipeDraftLocalDataSource {
  final Isar _isar;
  static const String _draftKey = 'current_draft';
  static const int _draftTtlDays = 7;

  RecipeDraftLocalDataSource(this._isar);

  Future<void> saveDraft(RecipeDraftDto draft) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.recipeDraftEntrys
          .filter()
          .draftKeyEqualTo(_draftKey)
          .findFirst();

      final entry = RecipeDraftEntry()
        ..draftKey = _draftKey
        ..jsonData = jsonEncode(draft.toJson())
        ..createdAt = DateTime.now();

      if (existing != null) {
        entry.id = existing.id;
      }
      await _isar.recipeDraftEntrys.put(entry);
    });
  }

  Future<RecipeDraftDto?> getDraft() async {
    final entry = await _isar.recipeDraftEntrys
        .filter()
        .draftKeyEqualTo(_draftKey)
        .findFirst();

    if (entry == null) return null;

    try {
      if (DateTime.now().difference(entry.createdAt).inDays > _draftTtlDays) {
        await clearDraft();
        return null;
      }

      return RecipeDraftDto.fromJson(jsonDecode(entry.jsonData));
    } catch (e) {
      await clearDraft();
      return null;
    }
  }

  Future<bool> hasDraft() async {
    final entry = await _isar.recipeDraftEntrys
        .filter()
        .draftKeyEqualTo(_draftKey)
        .findFirst();

    if (entry == null) return false;

    try {
      if (DateTime.now().difference(entry.createdAt).inDays > _draftTtlDays) {
        await clearDraft();
        return false;
      }
      return true;
    } catch (e) {
      await clearDraft();
      return false;
    }
  }

  Future<void> clearDraft() async {
    await _isar.writeTxn(() async {
      await _isar.recipeDraftEntrys
          .filter()
          .draftKeyEqualTo(_draftKey)
          .deleteAll();
    });
  }

  Future<DateTime?> getDraftSavedAt() async {
    final entry = await _isar.recipeDraftEntrys
        .filter()
        .draftKeyEqualTo(_draftKey)
        .findFirst();

    return entry?.createdAt;
  }
}
