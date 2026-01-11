import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/providers/analytics_providers.dart';
import 'package:pairing_planet2_frontend/domain/entities/analytics/app_event.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/create_recipe_request.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_modifiable.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/update_recipe_request.dart';
import 'package:pairing_planet2_frontend/domain/repositories/analytics_repository.dart';
import 'package:pairing_planet2_frontend/domain/repositories/recipe_repository.dart';
import 'package:pairing_planet2_frontend/domain/usecases/recipe/create_recipe_usecase.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';
import 'package:uuid/uuid.dart';

// ----------------------------------------------------------------
// Recipe Creation with Analytics
// ----------------------------------------------------------------

final recipeCreationProvider =
    StateNotifierProvider<RecipeCreationNotifier, AsyncValue<String?>>((ref) {
  return RecipeCreationNotifier(
    ref.read(createRecipeUseCaseProvider),
    ref.read(analyticsRepositoryProvider),
  );
});

class RecipeCreationNotifier extends StateNotifier<AsyncValue<String?>> {
  final CreateRecipeUseCase _useCase;
  final AnalyticsRepository _analyticsRepository;

  RecipeCreationNotifier(this._useCase, this._analyticsRepository)
      : super(const AsyncValue.data(null));

  Future<void> createRecipe(CreateRecipeRequest request) async {
    state = const AsyncValue.loading();
    final result = await _useCase.execute(request);

    state = result.fold(
      (failure) {
        return AsyncValue.error(failure.message, StackTrace.current);
      },
      (recipeId) {
        final isVariation = request.parentPublicId != null;

        _analyticsRepository.trackEvent(AppEvent(
          eventId: const Uuid().v4(),
          eventType:
              isVariation ? EventType.variationCreated : EventType.recipeCreated,
          timestamp: DateTime.now(),
          priority: EventPriority.immediate,
          recipeId: recipeId,
          properties: {
            'ingredient_count': request.ingredients.length,
            'step_count': request.steps.length,
            'has_images': request.imagePublicIds.isNotEmpty,
            'image_count': request.imagePublicIds.length,
            if (isVariation) 'parent_recipe_id': request.parentPublicId,
            if (isVariation && request.rootPublicId != null)
              'root_recipe_id': request.rootPublicId,
            if (isVariation) 'change_category': request.changeCategory ?? '',
          },
        ));

        return AsyncValue.data(recipeId);
      },
    );
  }
}

// ----------------------------------------------------------------
// Recipe Save/Bookmark
// ----------------------------------------------------------------

class SaveRecipeNotifier extends StateNotifier<AsyncValue<bool>> {
  final RecipeRepository _repository;
  final String _recipeId;

  SaveRecipeNotifier(this._repository, this._recipeId)
      : super(const AsyncValue.data(false));

  void setInitialState(bool isSaved) {
    state = AsyncValue.data(isSaved);
  }

  Future<void> toggle() async {
    final currentlySaved = state.value ?? false;
    state = const AsyncValue.loading();

    final result = currentlySaved
        ? await _repository.unsaveRecipe(_recipeId)
        : await _repository.saveRecipe(_recipeId);

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => AsyncValue.data(!currentlySaved),
    );
  }
}

final saveRecipeProvider =
    StateNotifierProvider.family<SaveRecipeNotifier, AsyncValue<bool>, String>(
  (ref, recipeId) {
    final repository = ref.read(recipeRepositoryProvider);
    return SaveRecipeNotifier(repository, recipeId);
  },
);

// ----------------------------------------------------------------
// Recipe Modifiable Check
// ----------------------------------------------------------------

final recipeModifiableProvider =
    FutureProvider.family<RecipeModifiable, String>(
  (ref, publicId) async {
    final repository = ref.watch(recipeRepositoryProvider);
    final result = await repository.checkRecipeModifiable(publicId);
    return result.fold(
      (failure) => throw failure.message,
      (modifiable) => modifiable,
    );
  },
);

// ----------------------------------------------------------------
// Recipe Update
// ----------------------------------------------------------------

class RecipeUpdateNotifier extends StateNotifier<AsyncValue<RecipeDetail?>> {
  final RecipeRepository _repository;
  final AnalyticsRepository _analyticsRepository;

  RecipeUpdateNotifier(this._repository, this._analyticsRepository)
      : super(const AsyncValue.data(null));

  Future<bool> updateRecipe(
      String publicId, UpdateRecipeRequest request) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateRecipe(publicId, request);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (recipe) {
        _analyticsRepository.trackEvent(AppEvent(
          eventId: const Uuid().v4(),
          eventType: EventType.recipeUpdated,
          timestamp: DateTime.now(),
          priority: EventPriority.immediate,
          recipeId: publicId,
          properties: {
            'ingredient_count': request.ingredients.length,
            'step_count': request.steps.length,
            'image_count': request.imagePublicIds.length,
          },
        ));

        state = AsyncValue.data(recipe);
        return true;
      },
    );
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final recipeUpdateProvider =
    StateNotifierProvider<RecipeUpdateNotifier, AsyncValue<RecipeDetail?>>(
        (ref) {
  return RecipeUpdateNotifier(
    ref.read(recipeRepositoryProvider),
    ref.read(analyticsRepositoryProvider),
  );
});

// ----------------------------------------------------------------
// Recipe Delete
// ----------------------------------------------------------------

class RecipeDeleteNotifier extends StateNotifier<AsyncValue<bool>> {
  final RecipeRepository _repository;
  final AnalyticsRepository _analyticsRepository;

  RecipeDeleteNotifier(this._repository, this._analyticsRepository)
      : super(const AsyncValue.data(false));

  Future<bool> deleteRecipe(String publicId) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteRecipe(publicId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        _analyticsRepository.trackEvent(AppEvent(
          eventId: const Uuid().v4(),
          eventType: EventType.recipeDeleted,
          timestamp: DateTime.now(),
          priority: EventPriority.immediate,
          recipeId: publicId,
        ));

        state = const AsyncValue.data(true);
        return true;
      },
    );
  }

  void reset() {
    state = const AsyncValue.data(false);
  }
}

final recipeDeleteProvider =
    StateNotifierProvider<RecipeDeleteNotifier, AsyncValue<bool>>((ref) {
  return RecipeDeleteNotifier(
    ref.read(recipeRepositoryProvider),
    ref.read(analyticsRepositoryProvider),
  );
});
