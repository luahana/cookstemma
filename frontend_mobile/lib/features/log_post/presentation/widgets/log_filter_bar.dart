import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/outcome_badge.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_filter_provider.dart';

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
          _OutcomeFilterChip(
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
          _OutcomeFilterChip(
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
          _OutcomeFilterChip(
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
          _OutcomeFilterChip(
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
          _TimeFilterDropdown(
            currentFilter: filterState.timeFilter,
            onChanged: (filter) {
              HapticFeedback.selectionClick();
              ref.read(logFilterProvider.notifier).setTimeFilter(filter);
              onFilterChanged?.call();
            },
          ),
          SizedBox(width: 8.w),
          // Photos only toggle
          _ToggleFilterChip(
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
          _SortDropdown(
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

/// Outcome filter chip with emoji and color
class _OutcomeFilterChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final Color? color;
  final Color? backgroundColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _OutcomeFilterChip({
    required this.label,
    this.emoji,
    this.color,
    this.backgroundColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final effectiveBgColor = backgroundColor ?? AppColors.primary.withValues(alpha: 0.1);

    return Semantics(
      button: true,
      label: '$label filter',
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? effectiveColor : effectiveBgColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected ? effectiveColor : effectiveColor.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: effectiveColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2.h),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: TextStyle(fontSize: 14.sp)),
                SizedBox(width: 6.w),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : effectiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toggle filter chip with icon
class _ToggleFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleFilterChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.grey[100],
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16.sp,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              SizedBox(width: 4.w),
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
      ),
    );
  }
}

/// Time filter dropdown
class _TimeFilterDropdown extends StatelessWidget {
  final LogTimeFilter currentFilter;
  final ValueChanged<LogTimeFilter> onChanged;

  const _TimeFilterDropdown({
    required this.currentFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: currentFilter != LogTimeFilter.all ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: currentFilter != LogTimeFilter.all ? AppColors.primary.withValues(alpha: 0.3) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LogTimeFilter>(
          value: currentFilter,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 18.sp,
            color: currentFilter != LogTimeFilter.all ? AppColors.primary : Colors.grey[600],
          ),
          isDense: true,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: currentFilter != LogTimeFilter.all ? AppColors.primary : Colors.grey[700],
          ),
          items: [
            DropdownMenuItem(
              value: LogTimeFilter.all,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14.sp, color: Colors.grey[600]),
                  SizedBox(width: 6.w),
                  Text('logPost.filter.time.all'.tr()),
                ],
              ),
            ),
            DropdownMenuItem(
              value: LogTimeFilter.today,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.today, size: 14.sp, color: AppColors.primary),
                  SizedBox(width: 6.w),
                  Text('logPost.filter.time.today'.tr()),
                ],
              ),
            ),
            DropdownMenuItem(
              value: LogTimeFilter.thisWeek,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.date_range, size: 14.sp, color: AppColors.primary),
                  SizedBox(width: 6.w),
                  Text('logPost.filter.time.thisWeek'.tr()),
                ],
              ),
            ),
            DropdownMenuItem(
              value: LogTimeFilter.thisMonth,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month, size: 14.sp, color: AppColors.primary),
                  SizedBox(width: 6.w),
                  Text('logPost.filter.time.thisMonth'.tr()),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

/// Sort dropdown
class _SortDropdown extends StatelessWidget {
  final LogSortOption currentSort;
  final ValueChanged<LogSortOption> onChanged;

  const _SortDropdown({
    required this.currentSort,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LogSortOption>(
          value: currentSort,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 18.sp,
            color: Colors.grey[600],
          ),
          isDense: true,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
          items: [
            DropdownMenuItem(
              value: LogSortOption.recent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 14.sp, color: Colors.grey[600]),
                  SizedBox(width: 6.w),
                  Text('logPost.filter.sort.recent'.tr()),
                ],
              ),
            ),
            DropdownMenuItem(
              value: LogSortOption.oldest,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 14.sp, color: Colors.grey[600]),
                  SizedBox(width: 6.w),
                  Text('logPost.filter.sort.oldest'.tr()),
                ],
              ),
            ),
            DropdownMenuItem(
              value: LogSortOption.outcomeSuccess,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(LogOutcome.success.emoji, style: TextStyle(fontSize: 12.sp)),
                  SizedBox(width: 6.w),
                  Text('logPost.filter.sort.winsFirst'.tr()),
                ],
              ),
            ),
            DropdownMenuItem(
              value: LogSortOption.outcomeFailed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(LogOutcome.failed.emoji, style: TextStyle(fontSize: 12.sp)),
                  SizedBox(width: 6.w),
                  Text('logPost.filter.sort.lessonsFirst'.tr()),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

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
