import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/data/datasources/recipe/recently_viewed_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recently_viewed_recipe_dto.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';

/// Provider for the recently viewed local data source.
final recentlyViewedLocalDataSourceProvider = Provider(
  (ref) => RecentlyViewedLocalDataSource(),
);

/// Provider for recently viewed recipes.
final recentlyViewedRecipesProvider =
    StateNotifierProvider<RecentlyViewedNotifier, List<RecipeSummary>>(
  (ref) => RecentlyViewedNotifier(ref),
);

/// StateNotifier for managing recently viewed recipes.
class RecentlyViewedNotifier extends StateNotifier<List<RecipeSummary>> {
  final Ref _ref;

  RecentlyViewedNotifier(this._ref) : super([]) {
    _loadRecent();
  }

  /// Load recently viewed from local storage.
  Future<void> _loadRecent() async {
    final dataSource = _ref.read(recentlyViewedLocalDataSourceProvider);
    final dtos = await dataSource.getRecentRecipes();
    state = dtos.map((dto) => dto.toRecipeSummary()).toList();
  }

  /// Add a recipe to recently viewed (called from recipe detail screen).
  Future<void> addRecipe({
    required String publicId,
    required String title,
    required String foodName,
    String? thumbnailUrl,
  }) async {
    final dataSource = _ref.read(recentlyViewedLocalDataSourceProvider);

    final dto = RecentlyViewedRecipeDto(
      publicId: publicId,
      title: title,
      foodName: foodName,
      thumbnailUrl: thumbnailUrl,
      viewedAt: DateTime.now(),
    );

    await dataSource.addRecentRecipe(dto);
    await _loadRecent();
  }

  /// Remove a specific recipe.
  Future<void> removeRecipe(String publicId) async {
    final dataSource = _ref.read(recentlyViewedLocalDataSourceProvider);
    await dataSource.removeRecipe(publicId);
    await _loadRecent();
  }

  /// Clear all recently viewed.
  Future<void> clearAll() async {
    final dataSource = _ref.read(recentlyViewedLocalDataSourceProvider);
    await dataSource.clearAll();
    state = [];
  }
}
