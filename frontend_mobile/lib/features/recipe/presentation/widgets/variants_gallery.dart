import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';

/// Horizontal scrolling gallery showing variant recipes.
/// Only displayed for root/original recipes that have variants.
class VariantsGallery extends StatelessWidget {
  final List<RecipeSummary> variants;
  final String recipeId;

  const VariantsGallery({
    super.key,
    required this.variants,
    required this.recipeId,
  });

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'recipe.variantsGallery.title'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (variants.length > 3)
                TextButton(
                  onPressed: () {
                    context.push(RouteConstants.recipeVariationsPath(recipeId));
                  },
                  child: Text(
                    'recipe.variantsGallery.viewMore'.tr(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Horizontal scroll gallery
        SizedBox(
          height: 180.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            // itemExtent improves scroll performance by pre-calculating item sizes
            itemExtent: 152.w, // 140.w card + 12.w margin
            itemCount: variants.length,
            itemBuilder: (context, index) {
              return _buildVariantCard(context, variants[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVariantCard(BuildContext context, RecipeSummary variant) {
    return GestureDetector(
      onTap: () => context.push(RouteConstants.recipeDetailPath(variant.publicId)),
      child: Container(
        width: 140.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: variant.thumbnailUrl != null
                  ? AppCachedImage(
                      imageUrl: variant.thumbnailUrl!,
                      width: 140.w,
                      height: 100.h,
                      borderRadius: 12.r,
                    )
                  : Container(
                      width: 140.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.grey[400],
                        size: 32.sp,
                      ),
                    ),
            ),
            SizedBox(height: 8.h),
            // Title (max 2 lines)
            Text(
              variant.title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            // Creator name
            Text(
              "@${variant.creatorName}",
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            // Activity counts
            Row(
              children: [
                Icon(
                  Icons.alt_route,
                  size: 12.sp,
                  color: Colors.orange[700],
                ),
                SizedBox(width: 2.w),
                Text(
                  "${variant.variantCount}",
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.history_edu,
                  size: 12.sp,
                  color: AppColors.primary,
                ),
                SizedBox(width: 2.w),
                Text(
                  "${variant.logCount}",
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
