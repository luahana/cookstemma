import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/trending_tree_dto.dart';
import 'evolution_recipe_card.dart';

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
                          child: _SmallBentoCard(recipe: small1),
                        ),
                      SizedBox(height: spacing),
                      if (small2 != null)
                        SizedBox(
                          height: smallHeight,
                          child: _SmallBentoCard(recipe: small2),
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
                    child: _FeaturedTrendingCard(tree: featured),
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
                          child: _SmallTrendingCard(tree: small1),
                        ),
                      SizedBox(height: spacing),
                      if (small2 != null)
                        SizedBox(
                          height: smallHeight,
                          child: _SmallTrendingCard(tree: small2),
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

/// Featured card for TrendingTreeDto
class _FeaturedTrendingCard extends StatelessWidget {
  final TrendingTreeDto tree;

  const _FeaturedTrendingCard({required this.tree});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(RouteConstants.recipeDetailPath(tree.rootRecipeId));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              tree.thumbnail != null
                  ? Image.network(
                      tree.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.orange[200],
                        child: Icon(Icons.restaurant_menu, size: 60.sp, color: Colors.orange[400]),
                      ),
                    )
                  : Container(
                      color: Colors.orange[200],
                      child: Icon(Icons.restaurant_menu, size: 60.sp, color: Colors.orange[400]),
                    ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              // Content
              Positioned(
                left: 12.w,
                right: 12.w,
                bottom: 12.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tree.foodName ?? tree.title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      tree.title,
                      style: TextStyle(fontSize: 13.sp, color: Colors.white.withValues(alpha: 0.9)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        _buildMetricBadge(Icons.fork_right, tree.variantCount),
                        SizedBox(width: 8.w),
                        _buildMetricBadge(Icons.edit_note, tree.logCount),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBadge(IconData icon, int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: Colors.white),
          SizedBox(width: 4.w),
          Text(
            count.toString(),
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Small card for TrendingTreeDto
class _SmallTrendingCard extends StatelessWidget {
  final TrendingTreeDto tree;

  const _SmallTrendingCard({required this.tree});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(RouteConstants.recipeDetailPath(tree.rootRecipeId));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Row(
            children: [
              // Thumbnail - fixed width to prevent overflow
              SizedBox(
                width: 70.w,
                child: tree.thumbnail != null
                    ? Image.network(
                        tree.thumbnail!,
                        fit: BoxFit.cover,
                        height: double.infinity,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.restaurant_menu, color: Colors.grey, size: 20.sp),
                        ),
                      )
                    : Container(
                        color: Colors.orange[100],
                        child: Icon(Icons.restaurant_menu, color: Colors.orange[300], size: 20.sp),
                      ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tree.foodName ?? tree.title,
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.fork_right, size: 10.sp, color: Colors.grey[600]),
                          Text('${tree.variantCount}', style: TextStyle(fontSize: 9.sp, color: Colors.grey[600])),
                          SizedBox(width: 4.w),
                          Icon(Icons.edit_note, size: 10.sp, color: Colors.grey[600]),
                          Text('${tree.logCount}', style: TextStyle(fontSize: 9.sp, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small bento card for the side slots
class _SmallBentoCard extends StatelessWidget {
  final RecipeSummaryDto recipe;

  const _SmallBentoCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToRecipe(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Row(
            children: [
              // Thumbnail - fixed width to prevent overflow
              SizedBox(
                width: 70.w,
                child: recipe.thumbnail != null
                    ? Image.network(
                        recipe.thumbnail!,
                        fit: BoxFit.cover,
                        height: double.infinity,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.restaurant_menu, color: Colors.grey, size: 20.sp),
                        ),
                      )
                    : Container(
                        color: Colors.orange[100],
                        child: Icon(Icons.restaurant_menu, color: Colors.orange[300], size: 20.sp),
                      ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(8.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        recipe.foodName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      // Metrics row
                      Row(
                        children: [
                          Icon(Icons.fork_right, size: 10.sp, color: Colors.grey[600]),
                          SizedBox(width: 2.w),
                          Text(
                            '${recipe.variantCount ?? 0}',
                            style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                          ),
                          SizedBox(width: 6.w),
                          Icon(Icons.edit_note, size: 10.sp, color: Colors.grey[600]),
                          SizedBox(width: 2.w),
                          Text(
                            '${recipe.logCount ?? 0}',
                            style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToRecipe(BuildContext context) {
    HapticFeedback.lightImpact();
    context.push(RouteConstants.recipeDetailPath(recipe.publicId));
  }
}
