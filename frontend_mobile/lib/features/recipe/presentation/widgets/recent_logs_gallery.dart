import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';

/// Horizontal scrolling gallery showing recent cooking logs for a recipe.
/// Shows outcome emoji overlay on each log's thumbnail.
class RecentLogsGallery extends StatelessWidget {
  final List<LogPostSummary> logs;
  final String recipeId;

  const RecentLogsGallery({
    super.key,
    required this.logs,
    required this.recipeId,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return _buildEmptyState();
    }

    // Show only first 5 logs, use 6th to detect if there are more
    final displayLogs = logs.take(5).toList();
    final hasMore = logs.length > 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'recipe.recentLogs.title'.tr(),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasMore)
                    TextButton(
                      onPressed: () {
                        // Navigate to recipe-filtered log list
                        context.push('${RouteConstants.logPosts}?recipeId=$recipeId');
                      },
                      child: Text(
                        'recipe.recentLogs.viewAll'.tr(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'recipe.recentLogs.subtitle'.tr(),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Horizontal scroll gallery
        SizedBox(
          height: 130.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            itemCount: displayLogs.length,
            itemBuilder: (context, index) {
              return _buildLogCard(context, displayLogs[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogCard(BuildContext context, LogPostSummary log) {
    final outcomeEmoji = switch (log.outcome) {
      'SUCCESS' => '😊',
      'PARTIAL' => '😐',
      'FAILED' => '😢',
      _ => '🍳',
    };

    return GestureDetector(
      onTap: () => context.push(RouteConstants.logPostDetailPath(log.id)),
      child: Container(
        width: 100.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Column(
          children: [
            // Photo with outcome overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: log.thumbnailUrl != null
                      ? AppCachedImage(
                          imageUrl: log.thumbnailUrl!,
                          width: 100.w,
                          height: 100.w,
                          borderRadius: 12.r,
                        )
                      : Container(
                          width: 100.w,
                          height: 100.w,
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
                // Outcome emoji overlay
                Positioned(
                  right: 6.w,
                  bottom: 6.h,
                  child: Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      outcomeEmoji,
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            // Creator name
            if (log.creatorName != null)
              Text(
                "@${log.creatorName}",
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Same section header as non-empty state
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'recipe.recentLogs.title'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'recipe.recentLogs.subtitle'.tr(),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        // Empty state card with guidance
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(Icons.restaurant_menu, size: 48.sp, color: Colors.grey[300]),
              SizedBox(height: 12.h),
              Text(
                'recipe.recentLogs.emptyTitle'.tr(),
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'recipe.recentLogs.emptyCta'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 12.h),
              // Visual indicator pointing to bottom button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_downward, size: 16.sp, color: AppColors.primary),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Text(
                      'recipe.recentLogs.emptyButton'.tr(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
