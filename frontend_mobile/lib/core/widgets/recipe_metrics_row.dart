import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Displays variant count and log count metrics in a row.
///
/// Used in recipe cards to show fork (variants) and edit (logs) counts.
/// Supports two styles:
/// - [RecipeMetricsRow] - compact inline style for small cards
/// - [RecipeMetricsBadge] - badge style with background for featured cards
class RecipeMetricsRow extends StatelessWidget {
  final int variantCount;
  final int logCount;
  final Color? iconColor;
  final double? iconSize;
  final double? fontSize;
  final double? spacing;

  const RecipeMetricsRow({
    super.key,
    required this.variantCount,
    required this.logCount,
    this.iconColor,
    this.iconSize,
    this.fontSize,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? Colors.grey[600];
    final effectiveIconSize = iconSize ?? 10.sp;
    final effectiveFontSize = fontSize ?? 10.sp;
    final effectiveSpacing = spacing ?? 6.w;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.fork_right, size: effectiveIconSize, color: effectiveIconColor),
        SizedBox(width: 2.w),
        Text(
          '$variantCount',
          style: TextStyle(fontSize: effectiveFontSize, color: effectiveIconColor),
        ),
        SizedBox(width: effectiveSpacing),
        Icon(Icons.edit_note, size: effectiveIconSize, color: effectiveIconColor),
        SizedBox(width: 2.w),
        Text(
          '$logCount',
          style: TextStyle(fontSize: effectiveFontSize, color: effectiveIconColor),
        ),
      ],
    );
  }
}

/// Badge-style metric display with background for featured cards.
class RecipeMetricsBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? iconSize;
  final double? fontSize;

  const RecipeMetricsBadge({
    super.key,
    required this.icon,
    required this.count,
    this.backgroundColor,
    this.foregroundColor,
    this.iconSize,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.white.withValues(alpha: 0.2);
    final fgColor = foregroundColor ?? Colors.white;
    final effectiveIconSize = iconSize ?? 14.sp;
    final effectiveFontSize = fontSize ?? 12.sp;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: effectiveIconSize, color: fgColor),
          SizedBox(width: 4.w),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: effectiveFontSize,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Row of metric badges for featured cards.
class RecipeMetricsBadgeRow extends StatelessWidget {
  final int variantCount;
  final int logCount;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const RecipeMetricsBadgeRow({
    super.key,
    required this.variantCount,
    required this.logCount,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RecipeMetricsBadge(
          icon: Icons.fork_right,
          count: variantCount,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        ),
        SizedBox(width: 8.w),
        RecipeMetricsBadge(
          icon: Icons.edit_note,
          count: logCount,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        ),
      ],
    );
  }
}
