import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/models/log_outcome.dart';

// Re-export LogOutcome for backward compatibility
export 'package:pairing_planet2_frontend/core/models/log_outcome.dart';

/// Badge variants for different display contexts
enum OutcomeBadgeVariant {
  /// Full badge with emoji and label: [😊 Nailed It!]
  full,
  /// Compact badge with emoji only: [😊]
  compact,
  /// Header style: 😊 SUCCESS (large, for card headers)
  header,
  /// Chip style for filter bar
  chip,
}

/// Styled outcome badge widget for cooking logs
class OutcomeBadge extends StatelessWidget {
  final LogOutcome outcome;
  final OutcomeBadgeVariant variant;
  final bool isSelected;
  final VoidCallback? onTap;

  const OutcomeBadge({
    super.key,
    required this.outcome,
    this.variant = OutcomeBadgeVariant.full,
    this.isSelected = false,
    this.onTap,
  });

  /// Create badge from outcome string value
  factory OutcomeBadge.fromString({
    required String? outcomeValue,
    OutcomeBadgeVariant variant = OutcomeBadgeVariant.full,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    final outcome = LogOutcome.fromString(outcomeValue) ?? LogOutcome.partial;
    return OutcomeBadge(
      outcome: outcome,
      variant: variant,
      isSelected: isSelected,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case OutcomeBadgeVariant.full:
        return _buildFullBadge();
      case OutcomeBadgeVariant.compact:
        return _buildCompactBadge();
      case OutcomeBadgeVariant.header:
        return _buildHeaderBadge();
      case OutcomeBadgeVariant.chip:
        return _buildChipBadge();
    }
  }

  Widget _buildFullBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: outcome.backgroundColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: outcome.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            outcome.emoji,
            style: TextStyle(fontSize: 14.sp),
          ),
          SizedBox(width: 6.w),
          Text(
            outcome.label,
            style: TextStyle(
              color: outcome.primaryColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBadge() {
    return Container(
      padding: EdgeInsets.all(6.r),
      decoration: BoxDecoration(
        color: outcome.backgroundColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        outcome.emoji,
        style: TextStyle(fontSize: 16.sp),
      ),
    );
  }

  Widget _buildHeaderBadge() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          outcome.emoji,
          style: TextStyle(fontSize: 24.sp),
        ),
        SizedBox(width: 8.w),
        Text(
          outcome.value,
          style: TextStyle(
            color: outcome.primaryColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildChipBadge() {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? outcome.primaryColor : outcome.backgroundColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? outcome.primaryColor : outcome.primaryColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: outcome.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2.h),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              outcome.emoji,
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(width: 6.w),
            Text(
              outcome.label,
              style: TextStyle(
                color: isSelected ? Colors.white : outcome.primaryColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stats display showing outcome counts: "23 wins · 8 learning · 3 lessons"
class OutcomeStatsRow extends StatelessWidget {
  final int successCount;
  final int partialCount;
  final int failedCount;
  final bool compact;

  const OutcomeStatsRow({
    super.key,
    required this.successCount,
    required this.partialCount,
    required this.failedCount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompactStat(LogOutcome.success, successCount),
          SizedBox(width: 8.w),
          _buildCompactStat(LogOutcome.partial, partialCount),
          SizedBox(width: 8.w),
          _buildCompactStat(LogOutcome.failed, failedCount),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStat(LogOutcome.success, successCount),
        _buildDivider(),
        _buildStat(LogOutcome.partial, partialCount),
        _buildDivider(),
        _buildStat(LogOutcome.failed, failedCount),
      ],
    );
  }

  Widget _buildStat(LogOutcome outcome, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          outcome.emoji,
          style: TextStyle(fontSize: 14.sp),
        ),
        SizedBox(width: 4.w),
        Text(
          count.toString(),
          style: TextStyle(
            color: outcome.primaryColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStat(LogOutcome outcome, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          outcome.emoji,
          style: TextStyle(fontSize: 12.sp),
        ),
        SizedBox(width: 2.w),
        Text(
          count.toString(),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Text(
        '\u00B7',
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
