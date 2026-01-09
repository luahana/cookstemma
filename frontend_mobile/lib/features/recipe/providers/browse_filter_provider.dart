import 'package:flutter_riverpod/flutter_riverpod.dart';

/// View mode for recipe browse page
enum BrowseViewMode {
  list,
  grid,
  star,
}

/// Recipe type filter
enum RecipeTypeFilter {
  all,
  originals,
  variants,
}

/// Sort options for recipe list
enum RecipeSortOption {
  recent,
  trending,
  mostForked,
}

/// Filter state for recipe browse page
class BrowseFilterState {
  final BrowseViewMode viewMode;
  final String? cuisineFilter; // null = all cuisines
  final RecipeTypeFilter typeFilter;
  final RecipeSortOption sortOption;

  const BrowseFilterState({
    this.viewMode = BrowseViewMode.list,
    this.cuisineFilter,
    this.typeFilter = RecipeTypeFilter.all,
    this.sortOption = RecipeSortOption.recent,
  });

  BrowseFilterState copyWith({
    BrowseViewMode? viewMode,
    String? cuisineFilter,
    bool clearCuisineFilter = false,
    RecipeTypeFilter? typeFilter,
    RecipeSortOption? sortOption,
  }) {
    return BrowseFilterState(
      viewMode: viewMode ?? this.viewMode,
      cuisineFilter: clearCuisineFilter ? null : (cuisineFilter ?? this.cuisineFilter),
      typeFilter: typeFilter ?? this.typeFilter,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  /// Check if any filter is active (excluding view mode)
  bool get hasActiveFilters =>
      cuisineFilter != null ||
      typeFilter != RecipeTypeFilter.all ||
      sortOption != RecipeSortOption.recent;

  /// Get filter count for badge
  int get activeFilterCount {
    int count = 0;
    if (cuisineFilter != null) count++;
    if (typeFilter != RecipeTypeFilter.all) count++;
    if (sortOption != RecipeSortOption.recent) count++;
    return count;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrowseFilterState &&
          runtimeType == other.runtimeType &&
          viewMode == other.viewMode &&
          cuisineFilter == other.cuisineFilter &&
          typeFilter == other.typeFilter &&
          sortOption == other.sortOption;

  @override
  int get hashCode =>
      viewMode.hashCode ^
      cuisineFilter.hashCode ^
      typeFilter.hashCode ^
      sortOption.hashCode;
}

/// Notifier for managing browse filter state
class BrowseFilterNotifier extends Notifier<BrowseFilterState> {
  @override
  BrowseFilterState build() {
    return const BrowseFilterState();
  }

  void setViewMode(BrowseViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void setCuisineFilter(String? cuisineCode) {
    if (cuisineCode == null) {
      state = state.copyWith(clearCuisineFilter: true);
    } else {
      state = state.copyWith(cuisineFilter: cuisineCode);
    }
  }

  void setTypeFilter(RecipeTypeFilter filter) {
    state = state.copyWith(typeFilter: filter);
  }

  void setSortOption(RecipeSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  void clearAllFilters() {
    state = BrowseFilterState(viewMode: state.viewMode);
  }

  void resetToDefaults() {
    state = const BrowseFilterState();
  }
}

/// Provider for browse filter state
final browseFilterProvider =
    NotifierProvider<BrowseFilterNotifier, BrowseFilterState>(
  BrowseFilterNotifier.new,
);

/// Convenience providers for individual filter values
final browseViewModeProvider = Provider<BrowseViewMode>((ref) {
  return ref.watch(browseFilterProvider.select((state) => state.viewMode));
});

final browseCuisineFilterProvider = Provider<String?>((ref) {
  return ref.watch(browseFilterProvider.select((state) => state.cuisineFilter));
});

final browseTypeFilterProvider = Provider<RecipeTypeFilter>((ref) {
  return ref.watch(browseFilterProvider.select((state) => state.typeFilter));
});

final browseSortOptionProvider = Provider<RecipeSortOption>((ref) {
  return ref.watch(browseFilterProvider.select((state) => state.sortOption));
});
