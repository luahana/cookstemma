import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/providers/analytics_providers.dart';
import 'package:pairing_planet2_frontend/core/providers/recently_viewed_provider.dart';
import 'package:pairing_planet2_frontend/domain/entities/analytics/app_event.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';
import 'package:uuid/uuid.dart';

/// Recipe detail provider with view tracking and recently viewed updates
final recipeDetailWithTrackingProvider =
    FutureProvider.family<RecipeDetail, String>((ref, id) async {
  final useCase = ref.watch(getRecipeDetailUseCaseProvider);
  final analyticsRepo = ref.read(analyticsRepositoryProvider);

  final result = await useCase(id);

  return result.fold(
    (failure) => throw failure.message,
    (recipe) {
      // Track recipe view event
      analyticsRepo.trackEvent(AppEvent(
        eventId: const Uuid().v4(),
        eventType: EventType.recipeViewed,
        timestamp: DateTime.now(),
        priority: EventPriority.batched,
        recipeId: recipe.publicId,
        properties: {
          'has_parent': recipe.parentInfo != null,
          'has_root': recipe.rootInfo != null,
          'ingredient_count': recipe.ingredients.length,
          'step_count': recipe.steps.length,
        },
      ));

      // Add to recently viewed recipes for quick log picker
      ref.read(recentlyViewedRecipesProvider.notifier).addRecipe(
            publicId: recipe.publicId,
            title: recipe.title,
            foodName: recipe.foodName,
            thumbnailUrl:
                recipe.imageUrls.isNotEmpty ? recipe.imageUrls.first : null,
          );

      return recipe;
    },
  );
});
