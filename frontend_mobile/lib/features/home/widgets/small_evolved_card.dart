import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/app_radius.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/clickable_username.dart';
import 'package:pairing_planet2_frontend/core/widgets/recipe_type_label.dart';
import 'package:pairing_planet2_frontend/core/widgets/recipe_thumbnail.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/trending_tree_dto.dart';

/// Small card for evolved recipes - full bleed image with food name & username
class SmallEvolvedCard extends StatelessWidget {
  final TrendingTreeDto tree;

  const SmallEvolvedCard({super.key, required this.tree});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(RouteConstants.recipeDetailPath(tree.rootRecipeId));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.md,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image - full bleed
              RecipeThumbnail(
                imageUrl: tree.thumbnail,
                height: double.infinity,
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
              // Content - food name with type icon and username
              Positioned(
                left: 8.w,
                right: 8.w,
                bottom: 8.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RecipeTypeLabel(
                      foodName: tree.foodName ?? tree.title,
                      isVariant: false, // Evolved trees are always root/original recipes
                      fontSize: 12.sp,
                      color: Colors.white,
                    ),
                    SizedBox(height: 2.h),
                    if (tree.creatorName != null)
                      ClickableUsername(
                        username: tree.creatorName!,
                        creatorPublicId: tree.creatorPublicId,
                        fontSize: 10.sp,
                        color: AppColors.primary,
                        showPersonIcon: true,
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
