import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_filter_provider.dart';

/// Compact version of filter bar (just outcome chips)
class CompactLogFilterBar extends ConsumerWidget {
  final VoidCallback? onFilterChanged;

  const CompactLogFilterBar({
    super.key,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(logFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          _CompactChip(
            label: 'logPost.filter.all'.tr(),
            isSelected: filterState.selectedOutcomes.isEmpty,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(logFilterProvider.notifier).clearOutcomeFilters();
              onFilterChanged?.call();
            },
          ),
          SizedBox(width: 8.w),
          _CompactChip(
            emoji: LogOutcome.success.emoji,
            label: 'logPost.filter.wins'.tr(),
            isSelected: filterState.selectedOutcomes.contains(LogOutcome.success),
            color: LogOutcome.success.primaryColor,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(logFilterProvider.notifier).toggleOutcome(LogOutcome.success);
              onFilterChanged?.call();
            },
          ),
          SizedBox(width: 8.w),
          _CompactChip(
            emoji: LogOutcome.partial.emoji,
            label: 'logPost.filter.learning'.tr(),
            isSelected: filterState.selectedOutcomes.contains(LogOutcome.partial),
            color: LogOutcome.partial.primaryColor,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(logFilterProvider.notifier).toggleOutcome(LogOutcome.partial);
              onFilterChanged?.call();
            },
          ),
          SizedBox(width: 8.w),
          _CompactChip(
            emoji: LogOutcome.failed.emoji,
            label: 'logPost.filter.lessons'.tr(),
            isSelected: filterState.selectedOutcomes.contains(LogOutcome.failed),
            color: LogOutcome.failed.primaryColor,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(logFilterProvider.notifier).toggleOutcome(LogOutcome.failed);
              onFilterChanged?.call();
            },
          ),
        ],
      ),
    );
  }
}

class _CompactChip extends StatelessWidget {
  final String? emoji;
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _CompactChip({
    this.emoji,
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? effectiveColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? effectiveColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: TextStyle(fontSize: 12.sp)),
              SizedBox(width: 4.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
