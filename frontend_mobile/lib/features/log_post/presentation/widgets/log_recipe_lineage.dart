import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/recipe_link_card.dart';
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
          // Recipe card - using reusable RecipeLinkCard
          RecipeLinkCard(
            publicId: linkedRecipe!.publicId,
            title: linkedRecipe!.title,
            creatorName: linkedRecipe!.creatorName,
            thumbnailUrl: linkedRecipe!.thumbnailUrl,
            culinaryLocale: linkedRecipe!.culinaryLocale,
          ),
        ],
      ),
    );
  }
}
