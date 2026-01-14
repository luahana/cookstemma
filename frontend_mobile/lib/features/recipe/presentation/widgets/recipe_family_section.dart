import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/app_icons.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/recipe_link_card.dart';
import 'package:pairing_planet2_frontend/core/widgets/unified_recipe_card.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';

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
                      'recipe.variants.viewMore'.tr(),
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
          RecipeLinkCard(
            publicId: rootInfo!.publicId,
            title: rootInfo!.title,
            creatorName: rootInfo!.creatorName,
            thumbnailUrl: rootInfo!.thumbnailUrl,
            culinaryLocale: rootInfo!.culinaryLocale,
          ),
        ],
      ),
    );
  }
}

