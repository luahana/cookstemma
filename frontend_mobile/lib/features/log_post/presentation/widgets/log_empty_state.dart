import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/outcome_badge.dart';

/// Illustrated empty state for when there are no log posts
class LogEmptyState extends StatelessWidget {
  final VoidCallback? onStartLogging;
  final EmptyStateType type;

  const LogEmptyState({
    super.key,
    this.onStartLogging,
    this.type = EmptyStateType.noLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            _buildIllustration(),
            SizedBox(height: 32.h),
            // Title
            Text(
              _getTitle(),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            // Description
            Text(
              _getDescription(),
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            // CTA button
            if (onStartLogging != null) _buildCTAButton(),
            // Tips section
            if (type == EmptyStateType.noLogs) ...[
              SizedBox(height: 40.h),
              _buildTipsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    switch (type) {
      case EmptyStateType.noLogs:
        return _NoLogsIllustration();
      case EmptyStateType.noFilterResults:
        return _NoResultsIllustration();
      case EmptyStateType.offline:
        return _OfflineIllustration();
    }
  }

  String _getTitle() {
    switch (type) {
      case EmptyStateType.noLogs:
        return 'logPost.empty.noLogs.title'.tr();
      case EmptyStateType.noFilterResults:
        return 'logPost.empty.noResults.title'.tr();
      case EmptyStateType.offline:
        return 'logPost.empty.offline.title'.tr();
    }
  }

  String _getDescription() {
    switch (type) {
      case EmptyStateType.noLogs:
        return 'logPost.empty.noLogs.description'.tr();
      case EmptyStateType.noFilterResults:
        return 'logPost.empty.noResults.description'.tr();
      case EmptyStateType.offline:
        return 'logPost.empty.offline.description'.tr();
    }
  }

  Widget _buildCTAButton() {
    return FilledButton.icon(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onStartLogging?.call();
      },
      icon: const Icon(Icons.camera_alt_rounded),
      label: Text('logPost.empty.startLogging'.tr()),
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        textStyle: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'logPost.empty.tips.title'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildTip(
            emoji: LogOutcome.success.emoji,
            text: 'logPost.empty.tips.success'.tr(),
          ),
          SizedBox(height: 8.h),
          _buildTip(
            emoji: LogOutcome.partial.emoji,
            text: 'logPost.empty.tips.partial'.tr(),
          ),
          SizedBox(height: 8.h),
          _buildTip(
            emoji: LogOutcome.failed.emoji,
            text: 'logPost.empty.tips.failed'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildTip({required String emoji, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: TextStyle(fontSize: 16.sp)),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.primary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

enum EmptyStateType {
  noLogs,
  noFilterResults,
  offline,
}

/// Illustration for no logs state
class _NoLogsIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200.w,
      height: 160.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 140.w,
            height: 140.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
          ),
          // Pot illustration
          Positioned(
            bottom: 20.h,
            child: Container(
              width: 80.w,
              height: 60.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20.r),
                ),
              ),
            ),
          ),
          // Steam lines
          Positioned(
            top: 20.h,
            left: 60.w,
            child: _buildSteamLine(),
          ),
          Positioned(
            top: 30.h,
            left: 90.w,
            child: _buildSteamLine(),
          ),
          Positioned(
            top: 15.h,
            left: 120.w,
            child: _buildSteamLine(),
          ),
          // Camera icon
          Positioned(
            top: 10.h,
            right: 30.w,
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
          ),
          // Emoji faces at bottom
          Positioned(
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(LogOutcome.success.emoji, style: TextStyle(fontSize: 24.sp)),
                SizedBox(width: 8.w),
                Text(LogOutcome.partial.emoji, style: TextStyle(fontSize: 24.sp)),
                SizedBox(width: 8.w),
                Text(LogOutcome.failed.emoji, style: TextStyle(fontSize: 24.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteamLine() {
    return Container(
      width: 3.w,
      height: 30.h,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }
}

/// Illustration for no filter results
class _NoResultsIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160.w,
      height: 160.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: Colors.orange[50],
              shape: BoxShape.circle,
            ),
          ),
          // Search icon with X
          Icon(
            Icons.search_off,
            size: 60.sp,
            color: Colors.orange[300],
          ),
          // Filter chips floating around
          Positioned(
            top: 10.h,
            left: 10.w,
            child: _buildMiniChip(LogOutcome.success.emoji),
          ),
          Positioned(
            top: 30.h,
            right: 10.w,
            child: _buildMiniChip(LogOutcome.partial.emoji),
          ),
          Positioned(
            bottom: 20.h,
            left: 20.w,
            child: _buildMiniChip(LogOutcome.failed.emoji),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(String emoji) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Text(emoji, style: TextStyle(fontSize: 14.sp)),
    );
  }
}

/// Illustration for offline state
class _OfflineIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160.w,
      height: 160.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
          ),
          // Cloud with X
          Icon(
            Icons.cloud_off,
            size: 60.sp,
            color: Colors.grey[400],
          ),
          // Pending indicator
          Positioned(
            bottom: 20.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12.w,
                    height: 12.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.orange[600]),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'logPost.empty.offline.pending'.tr(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter-specific empty state
class FilterEmptyState extends StatelessWidget {
  final VoidCallback onClearFilters;

  const FilterEmptyState({
    super.key,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NoResultsIllustration(),
            SizedBox(height: 24.h),
            Text(
              'logPost.empty.noResults.title'.tr(),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'logPost.empty.noResults.tryDifferent'.tr(),
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onClearFilters();
              },
              icon: const Icon(Icons.filter_alt_off),
              label: Text('logPost.filter.clearAll'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
