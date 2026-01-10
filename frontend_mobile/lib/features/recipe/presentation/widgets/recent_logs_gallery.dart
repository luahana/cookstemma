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
                'recipe.recentLogs.title'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (logs.length > 3)
                TextButton(
                  onPressed: () {
                    // Navigate to full log list (future feature)
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
        ),
        SizedBox(height: 12.h),

        // Horizontal scroll gallery
        SizedBox(
          height: 130.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return _buildLogCard(context, logs[index]);
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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_edu,
            size: 40.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 12.h),
          Text(
            'recipe.recentLogs.emptyTitle'.tr(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'recipe.recentLogs.emptySubtitle'.tr(),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}
