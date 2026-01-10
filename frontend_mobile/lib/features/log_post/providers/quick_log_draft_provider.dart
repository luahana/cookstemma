import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/outcome_badge.dart';

/// State machine steps for quick log flow
/// Flow: Outcome (1) → Photo (2) → Notes (3) → Hashtags (4) → Submit
enum QuickLogStep {
  idle,
  selectingOutcome,
  capturingPhoto,
  addingNotes,
  addingHashtags,
  submitting,
  success,
  error,
}

/// Draft state for quick log in progress
class QuickLogDraft {
  final QuickLogStep step;
  final LogOutcome? outcome;
  final List<String> photoPaths;
  final List<String> photoPublicIds;
  final String? recipePublicId;
  final String? recipeTitle;
  final String? notes;
  final List<String> hashtags;
  final String? errorMessage;
  final DateTime createdAt;

  const QuickLogDraft({
    this.step = QuickLogStep.idle,
    this.outcome,
    this.photoPaths = const [],
    this.photoPublicIds = const [],
    this.recipePublicId,
    this.recipeTitle,
    this.notes,
    this.hashtags = const [],
    this.errorMessage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? const _DefaultDateTime();

  QuickLogDraft copyWith({
    QuickLogStep? step,
    LogOutcome? outcome,
    List<String>? photoPaths,
    List<String>? photoPublicIds,
    String? recipePublicId,
    String? recipeTitle,
    String? notes,
    List<String>? hashtags,
    String? errorMessage,
  }) {
    return QuickLogDraft(
      step: step ?? this.step,
      outcome: outcome ?? this.outcome,
      photoPaths: photoPaths ?? this.photoPaths,
      photoPublicIds: photoPublicIds ?? this.photoPublicIds,
      recipePublicId: recipePublicId ?? this.recipePublicId,
      recipeTitle: recipeTitle ?? this.recipeTitle,
      notes: notes ?? this.notes,
      hashtags: hashtags ?? this.hashtags,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt,
    );
  }

  /// Check if draft has minimum required data for submission
  /// Recipe is always pre-selected before reaching quick log sheet
  bool get canSubmit =>
      outcome != null && photoPaths.isNotEmpty && recipePublicId != null;

  /// Check if draft is in an active flow
  bool get isActive => step != QuickLogStep.idle && step != QuickLogStep.success;

  /// Progress percentage (0.0 - 1.0)
  /// 4 steps: Outcome → Photo → Notes → Hashtags
  double get progress {
    switch (step) {
      case QuickLogStep.idle:
        return 0.0;
      case QuickLogStep.selectingOutcome:
        return 0.2;
      case QuickLogStep.capturingPhoto:
        return 0.4;
      case QuickLogStep.addingNotes:
        return 0.6;
      case QuickLogStep.addingHashtags:
        return 0.8;
      case QuickLogStep.submitting:
        return 0.9;
      case QuickLogStep.success:
        return 1.0;
      case QuickLogStep.error:
        return 0.9;
    }
  }
}

/// Placeholder for const DateTime in default constructor
class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();

  @override
  dynamic noSuchMethod(Invocation invocation) => DateTime.now();
}

/// Notifier for managing quick log draft state
class QuickLogDraftNotifier extends Notifier<QuickLogDraft> {
  @override
  QuickLogDraft build() {
    return const QuickLogDraft();
  }

  /// Start a new quick log flow
  void startFlow() {
    state = QuickLogDraft(
      step: QuickLogStep.selectingOutcome,
      createdAt: DateTime.now(),
    );
  }

  /// Start a new quick log flow with a pre-selected recipe
  void startFlowWithRecipe(String recipePublicId, String recipeTitle) {
    state = QuickLogDraft(
      step: QuickLogStep.selectingOutcome,
      recipePublicId: recipePublicId,
      recipeTitle: recipeTitle,
      createdAt: DateTime.now(),
    );
  }

  /// Select the cooking outcome
  void selectOutcome(LogOutcome outcome) {
    state = state.copyWith(
      outcome: outcome,
      step: QuickLogStep.capturingPhoto,
    );
  }

  /// Add a photo to the list (max 3)
  /// Does NOT auto-advance - user must click Continue
  void addPhoto(String photoPath) {
    if (state.photoPaths.length >= 3) return;
    state = state.copyWith(
      photoPaths: [...state.photoPaths, photoPath],
    );
  }

  /// Remove a photo at the given index
  void removePhoto(int index) {
    if (index < 0 || index >= state.photoPaths.length) return;
    final newPaths = List<String>.from(state.photoPaths)..removeAt(index);
    state = state.copyWith(photoPaths: newPaths);
  }

  /// Reorder photos (drag-to-reorder)
  void reorderPhotos(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.photoPaths.length) return;
    if (newIndex < 0 || newIndex > state.photoPaths.length) return;
    if (newIndex > oldIndex) newIndex--;
    final newPaths = List<String>.from(state.photoPaths);
    final item = newPaths.removeAt(oldIndex);
    newPaths.insert(newIndex, item);
    state = state.copyWith(photoPaths: newPaths);
  }

  /// Proceed to notes step (explicit user action)
  void proceedToNotes() {
    if (state.photoPaths.isEmpty) return;
    state = state.copyWith(step: QuickLogStep.addingNotes);
  }

  /// Set photo public IDs (after upload)
  void setPhotoPublicIds(List<String> publicIds) {
    state = state.copyWith(photoPublicIds: publicIds);
  }

  /// Set optional notes and proceed to hashtags step
  void setNotes(String? notes) {
    state = state.copyWith(
      notes: notes,
      step: QuickLogStep.addingHashtags,
    );
  }

  /// Update notes without changing step (for text field onChange)
  void updateNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  /// Set hashtags
  void setHashtags(List<String> hashtags) {
    state = state.copyWith(hashtags: hashtags);
  }

  /// Move to submitting state
  void startSubmission() {
    state = state.copyWith(step: QuickLogStep.submitting);
  }

  /// Mark as successfully submitted
  void markSuccess() {
    state = state.copyWith(step: QuickLogStep.success);
  }

  /// Mark as error with message
  void markError(String message) {
    state = state.copyWith(
      step: QuickLogStep.error,
      errorMessage: message,
    );
  }

  /// Go back one step
  /// Flow: Outcome → Photo → Notes → Hashtags
  void goBack() {
    switch (state.step) {
      case QuickLogStep.capturingPhoto:
        state = state.copyWith(step: QuickLogStep.selectingOutcome);
        break;
      case QuickLogStep.addingNotes:
        state = state.copyWith(step: QuickLogStep.capturingPhoto);
        break;
      case QuickLogStep.addingHashtags:
        state = state.copyWith(step: QuickLogStep.addingNotes);
        break;
      case QuickLogStep.error:
        state = state.copyWith(step: QuickLogStep.addingHashtags);
        break;
      default:
        break;
    }
  }

  /// Cancel and reset the flow
  void cancel() {
    state = const QuickLogDraft();
  }

  /// Reset after successful submission
  void reset() {
    state = const QuickLogDraft();
  }
}

/// Provider for quick log draft state
final quickLogDraftProvider =
    NotifierProvider<QuickLogDraftNotifier, QuickLogDraft>(
  QuickLogDraftNotifier.new,
);
