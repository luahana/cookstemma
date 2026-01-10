import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Badge showing star metrics: variant count and log count
/// Used on original/root recipe cards to show the "star" (recipe family) size
class StarPreviewBadge extends StatelessWidget {
  final int variantCount;
  final int logCount;
  final bool compact;

  const StarPreviewBadge({
    super.key,
    required this.variantCount,
    required this.logCount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show if no activity
    if (variantCount == 0 && logCount == 0) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return _buildCompact();
    }

    return _buildFull();
  }

  Widget _buildFull() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '⭐',
            style: TextStyle(fontSize: 12.sp),
          ),
          SizedBox(width: 6.w),
          Text(
            'recipe.starLabel'.tr(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (variantCount > 0) ...[
            SizedBox(width: 8.w),
            Text(
              '🔀',
              style: TextStyle(fontSize: 10.sp),
            ),
            SizedBox(width: 2.w),
            Text(
              variantCount.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (logCount > 0) ...[
            SizedBox(width: 8.w),
            Text(
              '📝',
              style: TextStyle(fontSize: 10.sp),
            ),
            SizedBox(width: 2.w),
            Text(
              logCount.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompact() {
    final parts = <String>[];
    if (variantCount > 0) {
      parts.add('🔀$variantCount');
    }
    if (logCount > 0) {
      parts.add('📝$logCount');
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        parts.join(' · '),
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Badge showing "Based on: [Root Recipe Title]" for variant recipes
class BasedOnBadge extends StatelessWidget {
  final String rootTitle;
  final VoidCallback? onTap;

  const BasedOnBadge({
    super.key,
    required this.rootTitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '📍',
              style: TextStyle(fontSize: 11.sp),
            ),
            SizedBox(width: 4.w),
            Text(
              'recipe.basedOn'.tr(),
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10.sp,
              ),
            ),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                rootTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              SizedBox(width: 4.w),
              Icon(
                Icons.chevron_right,
                color: Colors.white70,
                size: 14.sp,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
