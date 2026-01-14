import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/app_icons.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/unified_recipe_card.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/locale_badge.dart';

/// Recipe Family Section - Shows lineage context
/// - For variants: Shows "Based on" with root recipe
/// - For originals: Shows "Variations" with variant thumbnails
class RecipeFamilySection extends StatelessWidget {
  final bool isOriginal;
  final RecipeSummary? rootInfo;
  final List<RecipeSummary> variants;
  final String currentRecipeId;

  const RecipeFamilySection({
    super.key,
    required this.isOriginal,
    this.rootInfo,
    required this.variants,
    required this.currentRecipeId,
  });

  @override
  Widget build(BuildContext context) {
    if (isOriginal) {
      return _buildVariationsSection(context);
    } else {
      return _buildBasedOnSection(context);
    }
  }

  /// For original recipes: Show "Variations" with variant list
  Widget _buildVariationsSection(BuildContext context) {
    // Show only first 5 variants, use 6th to detect if there are more
    final displayVariants = variants.take(5).toList();
    final hasMore = variants.length > 5;

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
                Icon(AppIcons.variantCreate, size: 20.sp, color: AppColors.primary),
                SizedBox(width: 8.w),
                Text(
                  'recipe.family.variations'.tr(),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (hasMore)
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push(RouteConstants.recipeVariationsPath(currentRecipeId));
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'recipe.variants.viewAll'.tr(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Empty state or variant list
          if (variants.isEmpty)
            _buildEmptyVariationsState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth * 0.75;
                return SizedBox(
                  height: 140.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                    itemCount: displayVariants.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < displayVariants.length - 1 ? 12.w : 0,
                        ),
                        child: Container(
                          width: cardWidth,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: UnifiedRecipeCard(
                              recipe: displayVariants[index],
                              isVertical: false,
                              showFoodName: false,
                              showDescription: false,
                              showMetrics: false,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// Empty state for variations section
  Widget _buildEmptyVariationsState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        children: [
          Text(
            'recipe.family.createVariationCta'.tr(),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'recipe.family.createVariationButton'.tr(),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(Icons.arrow_downward, size: 14.sp, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  /// For variant recipes: Show "Based on" with root recipe
  Widget _buildBasedOnSection(BuildContext context) {
    if (rootInfo == null) return const SizedBox.shrink();

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
                Icon(AppIcons.originalRecipe, size: 20.sp, color: AppColors.primary),
                SizedBox(width: 8.w),
                Text(
                  'recipe.family.basedOn'.tr(),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Root recipe card
          _RootRecipeCard(rootInfo: rootInfo!),
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
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: SizedBox(
                width: 50.w,
                height: 50.w,
                child: rootInfo.thumbnailUrl != null && rootInfo.thumbnailUrl!.isNotEmpty
                    ? AppCachedImage(
                        imageUrl: rootInfo.thumbnailUrl!,
                        width: 50.w,
                        height: 50.w,
                        borderRadius: 8.r,
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.restaurant, size: 24.sp, color: Colors.grey),
                      ),
              ),
            ),
            SizedBox(width: 12.w),
            // Recipe info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rootInfo.title,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (rootInfo.culinaryLocale.isNotEmpty) ...[
                        SizedBox(width: 8.w),
                        LocaleBadge(
                          localeCode: rootInfo.culinaryLocale,
                          showLabel: false,
                          fontSize: 12.sp,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '@${rootInfo.creatorName}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.primary,
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

