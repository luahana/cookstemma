import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/locale_dropdown.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/browse_filter_provider.dart';

/// Filter bar with cuisine chips, type filter, and sort options
class BrowseFilterBar extends ConsumerWidget {
  final VoidCallback? onFiltersChanged;

  const BrowseFilterBar({
    super.key,
    this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(browseFilterProvider);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cuisine filter chips (horizontal scroll)
          _buildCuisineChips(context, ref, filterState),
          const Divider(height: 1),
          // Type and sort filters row
          _buildTypeAndSortRow(context, ref, filterState),
        ],
      ),
    );
  }

  Widget _buildCuisineChips(
    BuildContext context,
    WidgetRef ref,
    BrowseFilterState filterState,
  ) {
    // Add "All" option at the beginning
    final allOptions = [
      _CuisineChipData(code: null, emoji: '🌐', labelKey: 'locale.all'),
      ...CulinaryLocale.options.map((locale) => _CuisineChipData(
            code: locale.code,
            emoji: locale.flagEmoji,
            labelKey: locale.labelKey,
          )),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: allOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = allOptions[index];
          final isSelected = filterState.cuisineFilter == option.code;

          return _CuisineChip(
            emoji: option.emoji,
            label: option.labelKey.tr(),
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(browseFilterProvider.notifier).setCuisineFilter(option.code);
              onFiltersChanged?.call();
            },
          );
        },
      ),
    );
  }

  Widget _buildTypeAndSortRow(
    BuildContext context,
    WidgetRef ref,
    BrowseFilterState filterState,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Type filter chips
          _TypeFilterChip(
            label: 'filter.all'.tr(),
            isSelected: filterState.typeFilter == RecipeTypeFilter.all,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(browseFilterProvider.notifier).setTypeFilter(RecipeTypeFilter.all);
              onFiltersChanged?.call();
            },
          ),
          const SizedBox(width: 8),
          _TypeFilterChip(
            label: 'filter.originals'.tr(),
            icon: Icons.push_pin_outlined,
            isSelected: filterState.typeFilter == RecipeTypeFilter.originals,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(browseFilterProvider.notifier).setTypeFilter(RecipeTypeFilter.originals);
              onFiltersChanged?.call();
            },
          ),
          const SizedBox(width: 8),
          _TypeFilterChip(
            label: 'filter.variants'.tr(),
            icon: Icons.call_split,
            isSelected: filterState.typeFilter == RecipeTypeFilter.variants,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(browseFilterProvider.notifier).setTypeFilter(RecipeTypeFilter.variants);
              onFiltersChanged?.call();
            },
          ),
          const Spacer(),
          // Sort dropdown
          _SortDropdown(
            currentSort: filterState.sortOption,
            onChanged: (option) {
              ref.read(browseFilterProvider.notifier).setSortOption(option);
              onFiltersChanged?.call();
            },
          ),
        ],
      ),
    );
  }
}

class _CuisineChipData {
  final String? code;
  final String emoji;
  final String labelKey;

  _CuisineChipData({
    required this.code,
    required this.emoji,
    required this.labelKey,
  });
}

class _CuisineChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CuisineChip({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeFilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppColors.primary : Colors.grey[600],
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final RecipeSortOption currentSort;
  final ValueChanged<RecipeSortOption> onChanged;

  const _SortDropdown({
    required this.currentSort,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<RecipeSortOption>(
      initialValue: currentSort,
      onSelected: onChanged,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              _getSortLabel(currentSort),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildSortMenuItem(RecipeSortOption.recent, 'filter.sortRecent'.tr(), Icons.access_time),
        _buildSortMenuItem(RecipeSortOption.trending, 'filter.sortTrending'.tr(), Icons.trending_up),
        _buildSortMenuItem(RecipeSortOption.mostForked, 'filter.sortMostForked'.tr(), Icons.call_split),
      ],
    );
  }

  PopupMenuItem<RecipeSortOption> _buildSortMenuItem(
    RecipeSortOption option,
    String label,
    IconData icon,
  ) {
    final isSelected = currentSort == option;
    return PopupMenuItem<RecipeSortOption>(
      value: option,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppColors.primary : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppColors.primary : Colors.grey[800],
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check, size: 18, color: AppColors.primary),
          ],
        ],
      ),
    );
  }

  String _getSortLabel(RecipeSortOption option) {
    switch (option) {
      case RecipeSortOption.recent:
        return 'filter.sortRecent'.tr();
      case RecipeSortOption.trending:
        return 'filter.sortTrending'.tr();
      case RecipeSortOption.mostForked:
        return 'filter.sortMostForked'.tr();
    }
  }
}

/// Compact filter bar showing active filter count with expand button
class CompactFilterBar extends ConsumerWidget {
  final VoidCallback onExpand;

  const CompactFilterBar({
    super.key,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(browseFilterProvider);
    final activeCount = filterState.activeFilterCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: onExpand,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: activeCount > 0 ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activeCount > 0 ? AppColors.primary : Colors.grey[300]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 16,
                    color: activeCount > 0 ? AppColors.primary : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'filter.filters'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: activeCount > 0 ? AppColors.primary : Colors.grey[600],
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        activeCount.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Show active cuisine chip if set
          if (filterState.cuisineFilter != null) ...[
            _buildActiveFilterChip(
              CulinaryLocale.fromCode(filterState.cuisineFilter)?.flagEmoji ?? '🌍',
              CulinaryLocale.fromCode(filterState.cuisineFilter)?.labelKey.tr() ?? '',
              () {
                ref.read(browseFilterProvider.notifier).setCuisineFilter(null);
              },
            ),
          ],
          const Spacer(),
          // Clear all button if filters active
          if (activeCount > 0)
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(browseFilterProvider.notifier).clearAllFilters();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'filter.clearAll'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(String emoji, String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
