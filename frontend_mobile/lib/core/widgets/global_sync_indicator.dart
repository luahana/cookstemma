import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/log_sync_engine.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/sync_queue_local_data_source.dart';

/// Global sync indicator that shows in top-right of main screens
/// Displays sync status with animated cloud icon
class GlobalSyncIndicator extends ConsumerWidget {
  const GlobalSyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(syncQueueStatsProvider);

    return statsAsync.when(
      data: (stats) {
        // Hide when everything is synced
        if (!stats.hasUnsyncedItems && stats.syncing == 0) {
          return const SizedBox.shrink();
        }

        return _SyncIndicatorContent(stats: stats);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _SyncIndicatorContent extends StatefulWidget {
  final SyncQueueStats stats;

  const _SyncIndicatorContent({required this.stats});

  @override
  State<_SyncIndicatorContent> createState() => _SyncIndicatorContentState();
}

class _SyncIndicatorContentState extends State<_SyncIndicatorContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _updateAnimation();
  }

  @override
  void didUpdateWidget(_SyncIndicatorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
  }

  void _updateAnimation() {
    if (widget.stats.syncing > 0) {
      _controller.repeat();
    } else if (widget.stats.hasUnsyncedItems) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSyncing = widget.stats.syncing > 0;
    final hasFailed = widget.stats.failed > 0;
    final pendingCount = widget.stats.needsSync;

    // Determine icon and color based on state
    final iconColor = hasFailed ? AppColors.error : AppColors.primary;
    final bgColor = hasFailed
        ? AppColors.error.withValues(alpha: 0.1)
        : AppColors.primary.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: () => _showSyncDetails(context),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: isSyncing ? 1.0 : _pulseAnimation.value,
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cloud icon with sync animation
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        hasFailed ? Icons.cloud_off : Icons.cloud_done,
                        color: iconColor,
                        size: 20.sp,
                      ),
                      if (isSyncing)
                        Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: Icon(
                            Icons.sync,
                            color: iconColor,
                            size: 14.sp,
                          ),
                        ),
                    ],
                  ),
                  // Badge count
                  if (pendingCount > 0) ...[
                    SizedBox(width: 4.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        pendingCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSyncDetails(BuildContext context) {
    final stats = widget.stats;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Status',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            _buildStatRow('Pending', stats.pending, AppColors.primary),
            _buildStatRow('Syncing', stats.syncing, AppColors.growth),
            _buildStatRow('Failed', stats.failed, AppColors.error),
            SizedBox(height: 16.h),
            Text(
              stats.hasUnsyncedItems
                  ? 'Your data will sync automatically when connected.'
                  : 'All data is synced!',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(fontSize: 14.sp),
          ),
          const Spacer(),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: count > 0 ? color : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
