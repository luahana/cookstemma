import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/compact_recipe_card.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/featured_star_card.dart';

/// Bento-style grid view for recipes
/// Features recipes with most variants in larger cards
class BentoGridView extends StatelessWidget {
  final List<RecipeSummary> recipes;
  final bool hasNext;
  final ScrollController? scrollController;
  final VoidCallback? onLoadMore;

  const BentoGridView({
    super.key,
    required this.recipes,
    this.hasNext = false,
    this.scrollController,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort recipes to find featured ones (most variants)
    final sortedRecipes = List<RecipeSummary>.from(recipes);
    sortedRecipes.sort((a, b) => b.variantCount.compareTo(a.variantCount));

    // Take top featured recipes (originals with most variants)
    final featuredRecipes = sortedRecipes
        .where((r) => !r.isVariant && r.variantCount >= 3)
        .take(3)
        .toList();

    // Create tile layout
    final tiles = _buildTileLayout(recipes, featuredRecipes);

    return MasonryGridView.count(
      controller: scrollController,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      padding: const EdgeInsets.all(16),
      itemCount: hasNext ? tiles.length + 1 : tiles.length,
      itemBuilder: (context, index) {
        if (hasNext && index == tiles.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final tile = tiles[index];
        return _buildTile(context, tile);
      },
    );
  }

  List<_GridTile> _buildTileLayout(
    List<RecipeSummary> allRecipes,
    List<RecipeSummary> featuredRecipes,
  ) {
    final tiles = <_GridTile>[];
    final featuredIds = featuredRecipes.map((r) => r.publicId).toSet();
    int normalIndex = 0;

    for (int i = 0; i < allRecipes.length; i++) {
      final recipe = allRecipes[i];

      if (featuredIds.contains(recipe.publicId)) {
        // Featured recipe - spans 2 columns
        tiles.add(_GridTile(
          recipe: recipe,
          type: _TileType.featured,
          height: 320,
        ));
      } else {
        // Regular recipe
        // Alternate heights for visual interest
        final isShort = normalIndex % 3 == 0;
        tiles.add(_GridTile(
          recipe: recipe,
          type: _TileType.compact,
          height: isShort ? 200 : 240,
        ));
        normalIndex++;
      }
    }

    return tiles;
  }

  Widget _buildTile(BuildContext context, _GridTile tile) {
    if (tile.type == _TileType.featured) {
      return SizedBox(
        height: tile.height,
        child: FeaturedStarCard(
          recipe: tile.recipe,
          onTap: () => context.push(RouteConstants.recipeDetailPath(tile.recipe.publicId)),
          onLog: () => context.push(RouteConstants.recipeDetailPath(tile.recipe.publicId)),
          onFork: () => context.push(RouteConstants.recipeDetailPath(tile.recipe.publicId)),
          onViewStar: () => context.push(RouteConstants.recipeDetailPath(tile.recipe.publicId)),
        ),
      );
    }

    return CompactRecipeCardFixed(
      recipe: tile.recipe,
      height: tile.height,
      onTap: () => context.push(RouteConstants.recipeDetailPath(tile.recipe.publicId)),
      onLog: () => context.push(RouteConstants.recipeDetailPath(tile.recipe.publicId)),
      onFork: () => context.push(RouteConstants.recipeDetailPath(tile.recipe.publicId)),
    );
  }
}

enum _TileType { featured, compact }

class _GridTile {
  final RecipeSummary recipe;
  final _TileType type;
  final double height;

  _GridTile({
    required this.recipe,
    required this.type,
    required this.height,
  });
}

/// Staggered grid view with quilt pattern for Bento layout
class BentoQuiltGridView extends StatelessWidget {
  final List<RecipeSummary> recipes;
  final bool hasNext;
  final ScrollController? scrollController;

  const BentoQuiltGridView({
    super.key,
    required this.recipes,
    this.hasNext = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort to find featured recipes
    final sortedRecipes = List<RecipeSummary>.from(recipes);
    sortedRecipes.sort((a, b) => b.variantCount.compareTo(a.variantCount));

    // Build quilt pattern
    return GridView.custom(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverQuiltedGridDelegate(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        repeatPattern: QuiltedGridRepeatPattern.inverted,
        pattern: _buildQuiltPattern(recipes),
      ),
      childrenDelegate: SliverChildBuilderDelegate(
        (context, index) {
          if (hasNext && index == recipes.length) {
            return const Center(child: CircularProgressIndicator());
          }

          if (index >= recipes.length) return null;

          final recipe = recipes[index];
          final isFeatured = !recipe.isVariant && recipe.variantCount >= 3;

          if (isFeatured) {
            return FeaturedStarCard(
              recipe: recipe,
              onTap: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
              onLog: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
              onFork: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
              onViewStar: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
            );
          }

          return CompactRecipeCard(
            recipe: recipe,
            onTap: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
            onLog: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
            onFork: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
          );
        },
        childCount: hasNext ? recipes.length + 1 : recipes.length,
      ),
    );
  }

  List<QuiltedGridTile> _buildQuiltPattern(List<RecipeSummary> recipes) {
    // Create a pattern that features recipes with most variants
    // Pattern repeats every 6 items
    return const [
      QuiltedGridTile(2, 2), // Featured (2x2)
      QuiltedGridTile(2, 1), // Compact
      QuiltedGridTile(2, 1), // Compact
      QuiltedGridTile(2, 1), // Compact
      QuiltedGridTile(2, 1), // Compact
      QuiltedGridTile(2, 2), // Featured (2x2)
    ];
  }
}

/// Simple uniform grid view for recipes
class SimpleGridView extends StatelessWidget {
  final List<RecipeSummary> recipes;
  final bool hasNext;
  final ScrollController? scrollController;

  const SimpleGridView({
    super.key,
    required this.recipes,
    this.hasNext = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: hasNext ? recipes.length + 1 : recipes.length,
      itemBuilder: (context, index) {
        if (hasNext && index == recipes.length) {
          return const Center(child: CircularProgressIndicator());
        }

        final recipe = recipes[index];
        return CompactRecipeCard(
          recipe: recipe,
          onTap: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
          onLog: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
          onFork: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
        );
      },
    );
  }
}

/// Featured stars horizontal carousel
class FeaturedStarsCarousel extends StatelessWidget {
  final List<RecipeSummary> recipes;
  final String? title;

  const FeaturedStarsCarousel({
    super.key,
    required this.recipes,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    // Filter to only show originals with many variants
    final featured = recipes
        .where((r) => !r.isVariant && r.variantCount >= 2)
        .toList()
      ..sort((a, b) => b.variantCount.compareTo(a.variantCount));

    if (featured.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full featured list
                  },
                  child: Text('grid.viewAll'.tr()),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: featured.length.clamp(0, 10),
            itemBuilder: (context, index) {
              final recipe = featured[index];
              return FeaturedStarCardHorizontal(
                recipe: recipe,
                onTap: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
              );
            },
          ),
        ),
      ],
    );
  }
}
