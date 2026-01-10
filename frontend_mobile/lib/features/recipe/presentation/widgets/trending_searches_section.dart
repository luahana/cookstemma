import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/features/home/providers/home_feed_provider.dart';

/// Section showing trending recipes from the home feed.
class TrendingSearchesSection extends ConsumerWidget {
  const TrendingSearchesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeFeedState = ref.watch(homeFeedProvider);
    final trendingTrees = homeFeedState.data?.trendingTrees ?? [];

    // Don't show section if no trending data
    if (trendingTrees.isEmpty && !homeFeedState.isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Text(
                '🔥',
                style: TextStyle(fontSize: 18.sp),
              ),
              SizedBox(width: 6.w),
              Text(
                'search.trendingThisWeek'.tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        // Trending items
        if (homeFeedState.isLoading && trendingTrees.isEmpty)
          _buildLoadingState()
        else
          ...trendingTrees.take(5).map((tree) => _TrendingRecipeTile(
                title: tree.title,
                foodName: tree.foodName,
                thumbnail: tree.thumbnail,
                variantCount: tree.variantCount,
                logCount: tree.logCount,
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push(RouteConstants.recipeDetailPath(tree.rootRecipeId));
                },
              )),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            margin: EdgeInsets.only(bottom: 8.h),
            height: 60.h,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendingRecipeTile extends StatelessWidget {
  final String title;
  final String? foodName;
  final String? thumbnail;
  final int variantCount;
  final int logCount;
  final VoidCallback onTap;

  const _TrendingRecipeTile({
    required this.title,
    this.foodName,
    this.thumbnail,
    required this.variantCount,
    required this.logCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: thumbnail != null
                  ? AppCachedImage(
                      imageUrl: thumbnail,
                      width: 50.w,
                      height: 50.w,
                      borderRadius: 0,
                    )
                  : Container(
                      width: 50.w,
                      height: 50.w,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.grey[400],
                        size: 24.sp,
                      ),
                    ),
            ),
            SizedBox(width: 12.w),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name
                  if (foodName != null)
                    Text(
                      foodName!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  // Stats
                  Row(
                    children: [
                      Icon(
                        Icons.call_split,
                        size: 12.sp,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '$variantCount',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.restaurant_menu,
                        size: 12.sp,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '$logCount',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}
