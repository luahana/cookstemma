import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';

/// State for star view containing root recipe and all its variants
class RecipeStarState {
  final RecipeSummary rootRecipe;
  final List<RecipeSummary> variants;
  final int totalLogs;

  const RecipeStarState({
    required this.rootRecipe,
    required this.variants,
    required this.totalLogs,
  });
}

/// Provider that fetches star data for a recipe.
/// If the given recipe is a variant, it will fetch the root recipe's star data.
final recipeStarProvider = FutureProvider.family<RecipeStarState, String>(
  (ref, recipeId) async {
    // First, get the recipe detail to determine if it's root or variant
    final detailResult = await ref.watch(recipeDetailProvider(recipeId).future);

    RecipeDetail rootDetail;

    // If this is a variant, we need to fetch the root recipe's detail
    if (detailResult.rootInfo != null) {
      // This is a variant, fetch root recipe detail
      rootDetail = await ref.watch(
        recipeDetailProvider(detailResult.rootInfo!.publicId).future,
      );
    } else {
      // This is already a root recipe
      rootDetail = detailResult;
    }

    // Convert root detail to summary for the star view
    final rootSummary = RecipeSummary(
      publicId: rootDetail.publicId,
      foodName: rootDetail.foodName,
      foodMasterPublicId: rootDetail.foodMasterPublicId,
      title: rootDetail.title,
      description: rootDetail.description ?? '',
      culinaryLocale: rootDetail.culinaryLocale ?? 'ko-KR',
      thumbnailUrl: rootDetail.imageUrls.isNotEmpty ? rootDetail.imageUrls.first : null,
      creatorName: '', // Not available in detail, could be added
      variantCount: rootDetail.variants.length,
      logCount: rootDetail.logs.length,
    );

    // Calculate total logs across all variants
    int totalLogs = rootDetail.logs.length;
    for (final variant in rootDetail.variants) {
      totalLogs += variant.logCount;
    }

    return RecipeStarState(
      rootRecipe: rootSummary,
      variants: rootDetail.variants,
      totalLogs: totalLogs,
    );
  },
);

/// Provider to get the selected recipe in star view
final selectedStarNodeProvider = StateProvider<RecipeSummary?>((ref) => null);
