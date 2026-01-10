import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/browse_filter_provider.dart';

/// Toggle button for switching between List, Grid, and Star view modes
class ViewModeToggle extends ConsumerWidget {
  final VoidCallback? onModeChanged;

  const ViewModeToggle({
    super.key,
    this.onModeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(browseViewModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewModeButton(
            icon: Icons.view_list,
            label: 'filter.viewList'.tr(),
            isSelected: currentMode == BrowseViewMode.list,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(browseFilterProvider.notifier).setViewMode(BrowseViewMode.list);
              onModeChanged?.call();
            },
            position: _ButtonPosition.left,
          ),
          _ViewModeButton(
            icon: Icons.grid_view,
            label: 'filter.viewGrid'.tr(),
            isSelected: currentMode == BrowseViewMode.grid,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(browseFilterProvider.notifier).setViewMode(BrowseViewMode.grid);
              onModeChanged?.call();
            },
            position: _ButtonPosition.middle,
          ),
          _ViewModeButton(
            icon: Icons.star_outline,
            label: 'filter.viewStar'.tr(),
            isSelected: currentMode == BrowseViewMode.star,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(browseFilterProvider.notifier).setViewMode(BrowseViewMode.star);
              onModeChanged?.call();
            },
            position: _ButtonPosition.right,
          ),
        ],
      ),
    );
  }
}

enum _ButtonPosition { left, middle, right }

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final _ButtonPosition position;

  const _ViewModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.position,
  });

  BorderRadius _getBorderRadius() {
    switch (position) {
      case _ButtonPosition.left:
        return BorderRadius.only(
          topLeft: Radius.circular(8.r),
          bottomLeft: Radius.circular(8.r),
        );
      case _ButtonPosition.middle:
        return BorderRadius.zero;
      case _ButtonPosition.right:
        return BorderRadius.only(
          topRight: Radius.circular(8.r),
          bottomRight: Radius.circular(8.r),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: _getBorderRadius(),
        ),
        child: Icon(
          icon,
          size: 20.sp,
          color: isSelected ? Colors.white : Colors.grey[600],
        ),
      ),
    );
  }
}

/// Compact view mode toggle for app bar
class CompactViewModeToggle extends ConsumerWidget {
  final VoidCallback? onModeChanged;

  const CompactViewModeToggle({
    super.key,
    this.onModeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(browseViewModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompactModeButton(
            icon: Icons.view_list,
            isSelected: currentMode == BrowseViewMode.list,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(browseFilterProvider.notifier).setViewMode(BrowseViewMode.list);
              onModeChanged?.call();
            },
            isFirst: true,
          ),
          _CompactModeButton(
            icon: Icons.grid_view,
            isSelected: currentMode == BrowseViewMode.grid,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(browseFilterProvider.notifier).setViewMode(BrowseViewMode.grid);
              onModeChanged?.call();
            },
            isFirst: false,
          ),
          _CompactModeButton(
            icon: Icons.star_outline,
            isSelected: currentMode == BrowseViewMode.star,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(browseFilterProvider.notifier).setViewMode(BrowseViewMode.star);
              onModeChanged?.call();
            },
            isFirst: false,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _CompactModeButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _CompactModeButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  BorderRadius _getBorderRadius() {
    if (isFirst) {
      return BorderRadius.only(
        topLeft: Radius.circular(6.r),
        bottomLeft: Radius.circular(6.r),
      );
    }
    if (isLast) {
      return BorderRadius.only(
        topRight: Radius.circular(6.r),
        bottomRight: Radius.circular(6.r),
      );
    }
    return BorderRadius.zero;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: _getBorderRadius(),
        ),
        child: Icon(
          icon,
          size: 16.sp,
          color: isSelected ? Colors.white : Colors.grey[600],
        ),
      ),
    );
  }
}

/// Icon-only view mode toggle for tight spaces
class IconViewModeToggle extends ConsumerWidget {
  final VoidCallback? onModeChanged;

  const IconViewModeToggle({
    super.key,
    this.onModeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(browseViewModeProvider);

    IconData getIcon() {
      switch (currentMode) {
        case BrowseViewMode.list:
          return Icons.view_list;
        case BrowseViewMode.grid:
          return Icons.grid_view;
        case BrowseViewMode.star:
          return Icons.star_outline;
      }
    }

    BrowseViewMode getNextMode() {
      switch (currentMode) {
        case BrowseViewMode.list:
          return BrowseViewMode.grid;
        case BrowseViewMode.grid:
          return BrowseViewMode.star;
        case BrowseViewMode.star:
          return BrowseViewMode.list;
      }
    }

    return IconButton(
      icon: Icon(getIcon()),
      onPressed: () {
        HapticFeedback.selectionClick();
        ref.read(browseFilterProvider.notifier).setViewMode(getNextMode());
        onModeChanged?.call();
      },
      tooltip: 'filter.viewList'.tr(),
    );
  }
}
