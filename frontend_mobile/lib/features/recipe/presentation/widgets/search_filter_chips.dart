import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_filter_chip.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/search_results_provider.dart';

/// Filter chips for search results.
/// Shows All, Recipes, Logs, Hashtags filter options.
class SearchFilterChips extends StatelessWidget {
  final SearchFilterMode currentMode;
  final ValueChanged<SearchFilterMode> onFilterChanged;

  const SearchFilterChips({
    super.key,
    required this.currentMode,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          AppFilterChip.icon(
            label: 'filter.recipes'.tr(),
            icon: Icons.restaurant_menu,
            isSelected: currentMode == SearchFilterMode.recipes,
            onTap: () => onFilterChanged(SearchFilterMode.recipes),
          ),
          SizedBox(width: 8.w),
          AppFilterChip.icon(
            label: 'filter.logs'.tr(),
            icon: Icons.history_edu,
            isSelected: currentMode == SearchFilterMode.logs,
            onTap: () => onFilterChanged(SearchFilterMode.logs),
          ),
          SizedBox(width: 8.w),
          AppFilterChip.icon(
            label: 'filter.hashtags'.tr(),
            icon: Icons.tag,
            isSelected: currentMode == SearchFilterMode.hashtags,
            onTap: () => onFilterChanged(SearchFilterMode.hashtags),
          ),
        ],
      ),
    );
  }
}
