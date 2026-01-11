import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Delegate for sticky tab bar in NestedScrollView
class StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

/// Cache indicator widget
Widget buildCacheIndicator({
  required bool isFromCache,
  required DateTime? cachedAt,
  required bool isLoading,
}) {
  if (!isFromCache || cachedAt == null) return const SizedBox.shrink();

  final diff = DateTime.now().difference(cachedAt);
  String timeText;
  if (diff.inMinutes < 1) {
    timeText = 'common.justNow'.tr();
  } else if (diff.inMinutes < 60) {
    timeText =
        'common.minutesAgo'.tr(namedArgs: {'count': diff.inMinutes.toString()});
  } else {
    timeText =
        'common.hoursAgo'.tr(namedArgs: {'count': diff.inHours.toString()});
  }

  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
    color: Colors.orange[50],
    child: Row(
      children: [
        Icon(Icons.access_time, size: 14.sp, color: Colors.orange[700]),
        SizedBox(width: 6.w),
        Text(
          'common.lastUpdatedTime'.tr(namedArgs: {'time': timeText}),
          style: TextStyle(fontSize: 12.sp, color: Colors.orange[700]),
        ),
        if (isLoading) ...[
          SizedBox(width: 8.w),
          SizedBox(
            width: 12.r,
            height: 12.r,
            child: CircularProgressIndicator(
              strokeWidth: 2.r,
              color: Colors.orange[700],
            ),
          ),
        ],
      ],
    ),
  );
}

/// Empty state widget for profile tabs
Widget buildProfileEmptyState({
  required IconData icon,
  required String message,
  required String subMessage,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64.sp, color: Colors.grey[400]),
        SizedBox(height: 16.h),
        Text(
          message,
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          subMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[500],
          ),
        ),
      ],
    ),
  );
}

/// Error state widget for profile tabs
Widget buildProfileErrorState(VoidCallback onRetry) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
        SizedBox(height: 16.h),
        Text(
          'common.couldNotLoad'.tr(),
          style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
        ),
        SizedBox(height: 16.h),
        ElevatedButton(
          onPressed: onRetry,
          child: Text('common.tryAgain'.tr()),
        ),
      ],
    ),
  );
}

/// Simple filter chip for profile tabs
Widget buildProfileFilterChip({
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.grey[200],
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
      ),
    ),
  );
}
