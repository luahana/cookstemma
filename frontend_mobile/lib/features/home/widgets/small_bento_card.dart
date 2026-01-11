import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/app_radius.dart';
import 'package:pairing_planet2_frontend/core/constants/app_spacing.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/widgets/recipe_metrics_row.dart';
import 'package:pairing_planet2_frontend/core/widgets/recipe_thumbnail.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';

/// Small bento card for the side slots
class SmallBentoCard extends StatelessWidget {
  final RecipeSummaryDto recipe;

  const SmallBentoCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToRecipe(context),
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
                  imageUrl: recipe.thumbnail,
                  height: double.infinity,
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: AppSpacing.paddingSm,
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
                      AppSpacing.verticalXs,
                      // Metrics row
                      RecipeMetricsRow(
                        variantCount: recipe.variantCount ?? 0,
                        logCount: recipe.logCount ?? 0,
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
