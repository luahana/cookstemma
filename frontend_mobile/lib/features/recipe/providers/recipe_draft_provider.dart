import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/providers/isar_provider.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_draft.dart';
import 'package:pairing_planet2_frontend/data/datasources/recipe/recipe_draft_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_draft_dto.dart';

/// Draft local data source provider
final recipeDraftLocalDataSourceProvider =
    Provider<RecipeDraftLocalDataSource>((ref) {
  final isar = ref.read(isarProvider);
  return RecipeDraftLocalDataSource(isar);
});

/// Draft save status enum
enum DraftSaveStatus { idle, saving, saved, error }

/// State class for draft management
class RecipeDraftState {
  final RecipeDraft? draft;
  final DraftSaveStatus saveStatus;
  final DateTime? lastSavedAt;
  final String? error;

  const RecipeDraftState({
    this.draft,
    this.saveStatus = DraftSaveStatus.idle,
    this.lastSavedAt,
    this.error,
  });

  RecipeDraftState copyWith({
    RecipeDraft? draft,
    DraftSaveStatus? saveStatus,
    DateTime? lastSavedAt,
    String? error,
  }) {
    return RecipeDraftState(
      draft: draft ?? this.draft,
      saveStatus: saveStatus ?? this.saveStatus,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      error: error,
    );
  }
}

/// StateNotifier for draft operations
class RecipeDraftNotifier extends StateNotifier<RecipeDraftState> {
  final RecipeDraftLocalDataSource _localDataSource;
  Timer? _autoSaveTimer;
  bool _isSaving = false;
  RecipeDraft? _lastSavedDraft;

  RecipeDraftNotifier(this._localDataSource) : super(const RecipeDraftState());

  /// Start auto-save timer (30 second interval)
  void startAutoSave(RecipeDraft Function() getCurrentDraft) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final draft = getCurrentDraft();
      if (draft.hasContent && draft != _lastSavedDraft) {
        saveDraft(draft);
      }
    });
  }

  /// Stop auto-save timer
  void stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// Save draft to local storage
  Future<void> saveDraft(RecipeDraft draft) async {
    if (_isSaving) return;
    if (!draft.hasContent) return;

    _isSaving = true;
    state = state.copyWith(
      draft: draft,
      saveStatus: DraftSaveStatus.saving,
    );

    try {
      await _localDataSource.saveDraft(RecipeDraftDto.fromEntity(draft));
      _lastSavedDraft = draft;
      state = state.copyWith(
        draft: draft,
        saveStatus: DraftSaveStatus.saved,
        lastSavedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        draft: draft,
        saveStatus: DraftSaveStatus.error,
        error: e.toString(),
      );
    } finally {
      _isSaving = false;
    }
  }

  /// Load draft from local storage
  Future<RecipeDraft?> loadDraft() async {
    final draftDto = await _localDataSource.getDraft();
    if (draftDto != null) {
      final draft = draftDto.toEntity();

      if (!draft.hasContent) {
        await _localDataSource.clearDraft();
        return null;
      }

      _lastSavedDraft = draft;
      state = RecipeDraftState(draft: draft);
      return draft;
    }
    return null;
  }

  /// Check if a draft exists
  Future<bool> hasDraft() async {
    return await _localDataSource.hasDraft();
  }

  /// Clear the draft from local storage
  Future<void> clearDraft() async {
    await _localDataSource.clearDraft();
    _lastSavedDraft = null;
    state = const RecipeDraftState();
  }

  /// Reset state to idle
  void resetStatus() {
    state = state.copyWith(saveStatus: DraftSaveStatus.idle);
  }

  @override
  void dispose() {
    stopAutoSave();
    super.dispose();
  }
}

/// Recipe draft provider
final recipeDraftProvider =
    StateNotifierProvider<RecipeDraftNotifier, RecipeDraftState>((ref) {
  return RecipeDraftNotifier(ref.read(recipeDraftLocalDataSourceProvider));
});
