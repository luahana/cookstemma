import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/trending_tree_dto.dart';

// Re-export card widgets for convenience
export 'featured_trending_card.dart';
export 'small_trending_card.dart';
export 'small_bento_card.dart';

import 'evolution_recipe_card.dart';
import 'featured_trending_card.dart';
import 'small_trending_card.dart';
import 'small_bento_card.dart';

/// Bento Box grid layout - 1 large featured card + 2 smaller cards
class BentoGridSection extends StatelessWidget {
  final List<RecipeSummaryDto> recipes;
  final EdgeInsets padding;

  BentoGridSection({
    super.key,
    required this.recipes,
    EdgeInsets? padding,
  }) : padding = padding ?? EdgeInsets.symmetric(horizontal: 16.w);

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) return const SizedBox.shrink();

    // Take first 3 recipes for the bento layout
    final featured = recipes.isNotEmpty ? recipes[0] : null;
    final small1 = recipes.length > 1 ? recipes[1] : null;
    final small2 = recipes.length > 2 ? recipes[2] : null;

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final spacing = 12.w;
          // Featured card takes 60% width, small cards share 40%
          final featuredWidth = (totalWidth - spacing) * 0.6;
          final featuredHeight = 220.h;
          final smallHeight = (featuredHeight - spacing) / 2;

          return SizedBox(
            height: featuredHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured large card (left)
                if (featured != null)
                  SizedBox(
                    width: featuredWidth,
                    height: featuredHeight,
                    child: FeaturedEvolutionCard(recipe: featured),
                  ),
                SizedBox(width: spacing),
                // Two small cards stacked (right)
                Expanded(
                  child: Column(
                    children: [
                      if (small1 != null)
                        SizedBox(
                          height: smallHeight,
                          child: SmallBentoCard(recipe: small1),
                        ),
                      SizedBox(height: spacing),
                      if (small2 != null)
                        SizedBox(
                          height: smallHeight,
                          child: SmallBentoCard(recipe: small2),
                        )
                      else
                        SizedBox(height: smallHeight),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Bento grid from TrendingTreeDto list
class BentoGridFromTrending extends StatelessWidget {
  final List<TrendingTreeDto> trendingTrees;
  final EdgeInsets padding;

  BentoGridFromTrending({
    super.key,
    required this.trendingTrees,
    EdgeInsets? padding,
  }) : padding = padding ?? EdgeInsets.symmetric(horizontal: 16.w);

  @override
  Widget build(BuildContext context) {
    if (trendingTrees.isEmpty) return const SizedBox.shrink();

    final featured = trendingTrees.isNotEmpty ? trendingTrees[0] : null;
    final small1 = trendingTrees.length > 1 ? trendingTrees[1] : null;
    final small2 = trendingTrees.length > 2 ? trendingTrees[2] : null;

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spacing = 12.w;
          final featuredHeight = 220.h;
          final smallHeight = (featuredHeight - spacing) / 2;

          return SizedBox(
            height: featuredHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured large card (left)
                if (featured != null)
                  Expanded(
                    flex: 6,
                    child: FeaturedTrendingCard(tree: featured),
                  ),
                SizedBox(width: spacing),
                // Two small cards stacked (right)
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      if (small1 != null)
                        SizedBox(
                          height: smallHeight,
                          child: SmallTrendingCard(tree: small1),
                        ),
                      SizedBox(height: spacing),
                      if (small2 != null)
                        SizedBox(
                          height: smallHeight,
                          child: SmallTrendingCard(tree: small2),
                        )
                      else
                        SizedBox(height: smallHeight),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
