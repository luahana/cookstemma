import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/app_radius.dart';
import 'package:pairing_planet2_frontend/core/constants/app_spacing.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/widgets/recipe_metrics_row.dart';
import 'package:pairing_planet2_frontend/core/widgets/recipe_thumbnail.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/trending_tree_dto.dart';

/// Featured card for TrendingTreeDto
class FeaturedTrendingCard extends StatelessWidget {
  final TrendingTreeDto tree;

  const FeaturedTrendingCard({super.key, required this.tree});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(RouteConstants.recipeDetailPath(tree.rootRecipeId));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.lg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.lg,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              FeaturedRecipeThumbnail(imageUrl: tree.thumbnail),
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
                    AppSpacing.verticalXs,
                    Text(
                      tree.title,
                      style: TextStyle(fontSize: 13.sp, color: Colors.white.withValues(alpha: 0.9)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.verticalSm,
                    RecipeMetricsBadgeRow(
                      variantCount: tree.variantCount,
                      logCount: tree.logCount,
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
}
