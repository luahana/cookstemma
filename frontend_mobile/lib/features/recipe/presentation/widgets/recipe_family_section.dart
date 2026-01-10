import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';

/// Recipe Family Section - Star Layout
/// Shows root recipe prominently with all variants as direct siblings
class RecipeFamilySection extends StatelessWidget {
  final RecipeSummary rootInfo;
  final List<RecipeSummary> allVariants;
  final String currentRecipeId;

  const RecipeFamilySection({
    super.key,
    required this.rootInfo,
    required this.allVariants,
    required this.currentRecipeId,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out current recipe from variants list
    final siblingVariants = allVariants
        .where((v) => v.publicId != currentRecipeId)
        .toList();

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
                Icon(Icons.account_tree_outlined, size: 20.sp, color: AppColors.primary),
                SizedBox(width: 8.w),
                Text(
                  'recipe.family.title'.tr(),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Root recipe card
          _RootRecipeCard(rootInfo: rootInfo),
          // Sibling variants
          if (siblingVariants.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
              child: Row(
                children: [
                  Text(
                    'recipe.family.otherVariations'.tr(),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.badgeBackground,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${siblingVariants.length}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 100.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                itemCount: siblingVariants.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < siblingVariants.length - 1 ? 10.w : 0,
                    ),
                    child: _VariantMiniCard(
                      variant: siblingVariants[index],
                      isCurrentRecipe: false,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12.h),
          ],
        ],
      ),
    );
  }
}

/// Root recipe card - prominent display
class _RootRecipeCard extends StatelessWidget {
  final RecipeSummary rootInfo;

  const _RootRecipeCard({required this.rootInfo});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(RouteConstants.recipeDetailPath(rootInfo.publicId));
      },
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            // Root badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pin_drop_outlined, size: 14.sp, color: AppColors.primary),
                  SizedBox(width: 4.w),
                  Text(
                    'recipe.family.basedOn'.tr(),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            // Root recipe info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rootInfo.title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    rootInfo.foodName,
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

/// Mini card for variant in horizontal list
class _VariantMiniCard extends StatelessWidget {
  final RecipeSummary variant;
  final bool isCurrentRecipe;

  const _VariantMiniCard({
    required this.variant,
    required this.isCurrentRecipe,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCurrentRecipe
          ? null
          : () {
              HapticFeedback.lightImpact();
              context.push(RouteConstants.recipeDetailPath(variant.publicId));
            },
      child: Container(
        width: 140.w,
        decoration: BoxDecoration(
          color: isCurrentRecipe ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isCurrentRecipe ? AppColors.primary : AppColors.border,
            width: isCurrentRecipe ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(9.r)),
              child: SizedBox(
                width: 50.w,
                height: double.infinity,
                child: variant.thumbnailUrl != null && variant.thumbnailUrl!.isNotEmpty
                    ? AppCachedImage(
                        imageUrl: variant.thumbnailUrl!,
                        width: 50.w,
                        height: double.infinity,
                        borderRadius: 0,
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.restaurant, size: 20.sp, color: Colors.grey),
                      ),
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
                    // Title
                    Text(
                      variant.title,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isCurrentRecipe ? AppColors.primary : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    // Creator
                    Text(
                      '@${variant.creatorName}',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Current badge
                    if (isCurrentRecipe) ...[
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'recipe.family.current'.tr(),
                          style: TextStyle(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
