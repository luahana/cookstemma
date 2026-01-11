import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_detail.dart';

/// Recipe link card displayed on Log Post Detail screen.
/// Shows which recipe was used with a tappable card.
class LogRecipeLineage extends StatelessWidget {
  final LinkedRecipeInfo? linkedRecipe;

  const LogRecipeLineage({
    super.key,
    this.linkedRecipe,
  });

  @override
  Widget build(BuildContext context) {
    if (linkedRecipe == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                Icon(Icons.restaurant_menu, size: 20.sp, color: AppColors.primary),
                SizedBox(width: 8.w),
                Text(
                  'logPost.recipeUsed'.tr(),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Recipe card
          _RecipeCard(linkedRecipe: linkedRecipe!),
        ],
      ),
    );
  }
}

/// Tappable recipe card with icon, title, creator, and chevron
class _RecipeCard extends StatelessWidget {
  final LinkedRecipeInfo linkedRecipe;

  const _RecipeCard({required this.linkedRecipe});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go(RouteConstants.recipeDetailPath(linkedRecipe.publicId));
      },
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            // Placeholder thumbnail
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.restaurant, size: 24.sp, color: Colors.grey),
            ),
            SizedBox(width: 12.w),
            // Recipe info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    linkedRecipe.title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'by ${linkedRecipe.creatorName}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Navigate icon
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
