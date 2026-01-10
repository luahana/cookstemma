import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/log_sync_engine.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/sync_queue_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/sync/sync_queue_item.dart';

/// Indicator showing the current sync status
/// Used in app bars, cards, and status sections
class SyncStatusIndicator extends ConsumerWidget {
  final SyncStatusVariant variant;

  const SyncStatusIndicator({
    super.key,
    this.variant = SyncStatusVariant.badge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(syncQueueStatsProvider);

    return statsAsync.when(
      data: (stats) {
        if (!stats.hasUnsyncedItems) {
          return const SizedBox.shrink();
        }

        switch (variant) {
          case SyncStatusVariant.badge:
            return _buildBadge(stats);
          case SyncStatusVariant.banner:
            return _buildBanner(context, ref, stats);
          case SyncStatusVariant.icon:
            return _buildIcon(stats);
          case SyncStatusVariant.inline:
            return _buildInline(stats);
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildBadge(SyncQueueStats stats) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12.w,
            height: 12.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.orange[700]),
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            '${stats.needsSync}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context, WidgetRef ref, SyncQueueStats stats) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border(
          bottom: BorderSide(color: Colors.orange[200]!),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16.w,
            height: 16.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.orange[700]),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'logPost.sync.pendingItems'.tr(namedArgs: {'count': stats.needsSync.toString()}),
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.orange[900],
              ),
            ),
          ),
          if (stats.failed > 0)
            TextButton(
              onPressed: () {
                ref.read(logSyncEngineProvider).triggerSync();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'common.retry'.tr(),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIcon(SyncQueueStats stats) {
    return Stack(
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          color: Colors.orange[600],
          size: 24.sp,
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: EdgeInsets.all(2.r),
            decoration: BoxDecoration(
              color: Colors.orange[600],
              shape: BoxShape.circle,
            ),
            constraints: BoxConstraints(
              minWidth: 14.w,
              minHeight: 14.w,
            ),
            child: Text(
              '${stats.needsSync}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInline(SyncQueueStats stats) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_queue,
          size: 14.sp,
          color: Colors.orange[600],
        ),
        SizedBox(width: 4.w),
        Text(
          'logPost.sync.syncing'.tr(),
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.orange[700],
          ),
        ),
      ],
    );
  }
}

enum SyncStatusVariant {
  badge,   // Compact badge with count
  banner,  // Full-width banner with retry button
  icon,    // Just an icon with badge
  inline,  // Inline text indicator
}

/// Small sync indicator for individual cards
class CardSyncIndicator extends StatelessWidget {
  final SyncStatus status;
  final int? retryCount;

  const CardSyncIndicator({
    super.key,
    required this.status,
    this.retryCount,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SyncStatus.pending:
        return _buildPendingIndicator();
      case SyncStatus.syncing:
        return _buildSyncingIndicator();
      case SyncStatus.synced:
        return const SizedBox.shrink(); // No indicator for synced items
      case SyncStatus.failed:
        return _buildFailedIndicator();
      case SyncStatus.abandoned:
        return _buildAbandonedIndicator();
    }
  }

  Widget _buildPendingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_queue,
            size: 12.sp,
            color: Colors.grey[600],
          ),
          SizedBox(width: 4.w),
          Text(
            'logPost.sync.waiting'.tr(),
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.growth.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10.w,
            height: 10.w,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation(AppColors.growth),
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            'logPost.sync.uploading'.tr(),
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.growth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 12.sp,
            color: Colors.red[600],
          ),
          SizedBox(width: 4.w),
          Text(
            retryCount != null
                ? 'logPost.sync.retrying'.tr(namedArgs: {'count': retryCount.toString()})
                : 'logPost.sync.failed'.tr(),
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbandonedIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 12.sp,
            color: Colors.red[700],
          ),
          SizedBox(width: 4.w),
          Text(
            'logPost.sync.offline'.tr(),
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.red[800],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sync status badge overlay for images/cards
class SyncOverlayBadge extends StatelessWidget {
  final SyncStatus status;

  const SyncOverlayBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (status == SyncStatus.synced) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 8.w,
      bottom: 8.h,
      child: Container(
        padding: EdgeInsets.all(6.r),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: _getIcon(),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (status) {
      case SyncStatus.pending:
        return Colors.grey[100]!;
      case SyncStatus.syncing:
        return AppColors.growth.withValues(alpha: 0.1);
      case SyncStatus.failed:
        return Colors.red[50]!;
      case SyncStatus.abandoned:
        return Colors.red[100]!;
      case SyncStatus.synced:
        return Colors.transparent;
    }
  }

  Widget _getIcon() {
    switch (status) {
      case SyncStatus.pending:
        return Icon(Icons.cloud_queue, size: 14.sp, color: Colors.grey[600]);
      case SyncStatus.syncing:
        return SizedBox(
          width: 14.w,
          height: 14.w,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.growth),
          ),
        );
      case SyncStatus.failed:
        return Icon(Icons.error_outline, size: 14.sp, color: Colors.red[600]);
      case SyncStatus.abandoned:
        return Icon(Icons.cloud_off, size: 14.sp, color: Colors.red[700]);
      case SyncStatus.synced:
        return const SizedBox.shrink();
    }
  }
}
