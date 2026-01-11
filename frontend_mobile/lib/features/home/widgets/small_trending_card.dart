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

/// Small card for TrendingTreeDto
class SmallTrendingCard extends StatelessWidget {
  final TrendingTreeDto tree;

  const SmallTrendingCard({super.key, required this.tree});

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
          borderRadius: AppRadius.md,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.md,
          child: Row(
            children: [
              // Thumbnail - fixed width to prevent overflow
              SizedBox(
                width: 70.w,
                child: RecipeThumbnail(
                  imageUrl: tree.thumbnail,
                  height: double.infinity,
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
                      AppSpacing.verticalXs,
                      RecipeMetricsRow(
                        variantCount: tree.variantCount,
                        logCount: tree.logCount,
                        fontSize: 9.sp,
                        spacing: 4.w,
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
