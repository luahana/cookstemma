import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_filter_provider.dart';

// Re-export filter widgets for backward compatibility
export 'filters/outcome_filter_chip.dart';
export 'filters/toggle_filter_chip.dart';
export 'filters/time_filter_dropdown.dart';
export 'filters/sort_dropdown.dart';
export 'filters/compact_log_filter_bar.dart';

import 'filters/outcome_filter_chip.dart';
import 'filters/toggle_filter_chip.dart';
import 'filters/time_filter_dropdown.dart';
import 'filters/sort_dropdown.dart';

/// Filter bar for log post list with outcome chips, time filters, and sort options
class LogFilterBar extends ConsumerWidget {
  final VoidCallback? onFilterChanged;

  const LogFilterBar({
    super.key,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(logFilterProvider);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Outcome filter chips (scrollable row)
          _buildOutcomeFilterRow(context, ref, filterState),
          // Secondary filters row (time, photos, sort)
          _buildSecondaryFilterRow(context, ref, filterState),
          // Active filter indicator
          if (filterState.hasActiveFilters)
            _buildActiveFilterIndicator(context, ref, filterState),
        ],
      ),
    );
  }

  Widget _buildOutcomeFilterRow(BuildContext context, WidgetRef ref, LogFilterState filterState) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          // All filter chip
          OutcomeFilterChip(
            label: 'logPost.filter.all'.tr(),
            emoji: null,
            isSelected: filterState.selectedOutcomes.isEmpty,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(logFilterProvider.notifier).clearOutcomeFilters();
              onFilterChanged?.call();
            },
          ),
          SizedBox(width: 8.w),
          // Success (Wins)
          OutcomeFilterChip(
            label: 'logPost.filter.wins'.tr(),
            emoji: LogOutcome.success.emoji,
            color: LogOutcome.success.primaryColor,
            backgroundColor: LogOutcome.success.backgroundColor,
            isSelected: filterState.selectedOutcomes.contains(LogOutcome.success),
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(logFilterProvider.notifier).toggleOutcome(LogOutcome.success);
              onFilterChanged?.call();
            },
          ),
          SizedBox(width: 8.w),
          // Partial (Learning)
          OutcomeFilterChip(
            label: 'logPost.filter.learning'.tr(),
            emoji: LogOutcome.partial.emoji,
            color: LogOutcome.partial.primaryColor,
            backgroundColor: LogOutcome.partial.backgroundColor,
            isSelected: filterState.selectedOutcomes.contains(LogOutcome.partial),
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(logFilterProvider.notifier).toggleOutcome(LogOutcome.partial);
              onFilterChanged?.call();
            },
          ),
          SizedBox(width: 8.w),
          // Failed (Lessons)
          OutcomeFilterChip(
            label: 'logPost.filter.lessons'.tr(),
            emoji: LogOutcome.failed.emoji,
            color: LogOutcome.failed.primaryColor,
            backgroundColor: LogOutcome.failed.backgroundColor,
            isSelected: filterState.selectedOutcomes.contains(LogOutcome.failed),
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

  Widget _buildSecondaryFilterRow(BuildContext context, WidgetRef ref, LogFilterState filterState) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        children: [
          // Time filter dropdown
          TimeFilterDropdown(
            currentFilter: filterState.timeFilter,
            onChanged: (filter) {
              HapticFeedback.selectionClick();
              ref.read(logFilterProvider.notifier).setTimeFilter(filter);
              onFilterChanged?.call();
            },
          ),
          SizedBox(width: 8.w),
          // Photos only toggle
          ToggleFilterChip(
            icon: Icons.photo_camera_outlined,
            label: 'logPost.filter.withPhotos'.tr(),
            isSelected: filterState.showOnlyWithPhotos,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(logFilterProvider.notifier).togglePhotosOnly();
              onFilterChanged?.call();
            },
          ),
          SizedBox(width: 8.w),
          // Sort dropdown
          SortDropdown(
            currentSort: filterState.sortOption,
            onChanged: (sort) {
              HapticFeedback.selectionClick();
              ref.read(logFilterProvider.notifier).setSortOption(sort);
              onFilterChanged?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterIndicator(BuildContext context, WidgetRef ref, LogFilterState filterState) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 16.sp,
            color: AppColors.primary,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'logPost.filter.activeFilters'.tr(namedArgs: {'count': filterState.activeFilterCount.toString()}),
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(logFilterProvider.notifier).clearAllFilters();
              onFilterChanged?.call();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'logPost.filter.clearAll'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
