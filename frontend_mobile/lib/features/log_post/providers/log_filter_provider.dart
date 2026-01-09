import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/outcome_badge.dart';

/// Filter options for log post list
enum LogTimeFilter {
  all,
  today,
  thisWeek,
  thisMonth,
}

/// Sort options for log post list
enum LogSortOption {
  recent,
  oldest,
  outcomeSuccess,
  outcomeFailed,
}

/// State for log post filters
class LogFilterState {
  final Set<LogOutcome> selectedOutcomes;
  final LogTimeFilter timeFilter;
  final LogSortOption sortOption;
  final bool showOnlyWithPhotos;

  const LogFilterState({
    this.selectedOutcomes = const {},
    this.timeFilter = LogTimeFilter.all,
    this.sortOption = LogSortOption.recent,
    this.showOnlyWithPhotos = false,
  });

  /// Check if any filter is active (not default)
  bool get hasActiveFilters =>
      selectedOutcomes.isNotEmpty ||
      timeFilter != LogTimeFilter.all ||
      showOnlyWithPhotos;

  /// Get the count of active filters
  int get activeFilterCount {
    int count = 0;
    if (selectedOutcomes.isNotEmpty) count += selectedOutcomes.length;
    if (timeFilter != LogTimeFilter.all) count++;
    if (showOnlyWithPhotos) count++;
    return count;
  }

  LogFilterState copyWith({
    Set<LogOutcome>? selectedOutcomes,
    LogTimeFilter? timeFilter,
    LogSortOption? sortOption,
    bool? showOnlyWithPhotos,
  }) {
    return LogFilterState(
      selectedOutcomes: selectedOutcomes ?? this.selectedOutcomes,
      timeFilter: timeFilter ?? this.timeFilter,
      sortOption: sortOption ?? this.sortOption,
      showOnlyWithPhotos: showOnlyWithPhotos ?? this.showOnlyWithPhotos,
    );
  }

  /// Convert to query parameters for API
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (selectedOutcomes.isNotEmpty) {
      params['outcomes'] = selectedOutcomes.map((o) => o.value).toList();
    }

    if (timeFilter != LogTimeFilter.all) {
      final now = DateTime.now();
      switch (timeFilter) {
        case LogTimeFilter.today:
          params['fromDate'] = DateTime(now.year, now.month, now.day).toIso8601String();
          break;
        case LogTimeFilter.thisWeek:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          params['fromDate'] = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).toIso8601String();
          break;
        case LogTimeFilter.thisMonth:
          params['fromDate'] = DateTime(now.year, now.month, 1).toIso8601String();
          break;
        case LogTimeFilter.all:
          break;
      }
    }

    if (showOnlyWithPhotos) {
      params['hasPhotos'] = true;
    }

    // Sort
    switch (sortOption) {
      case LogSortOption.recent:
        params['sort'] = 'createdAt';
        params['order'] = 'desc';
        break;
      case LogSortOption.oldest:
        params['sort'] = 'createdAt';
        params['order'] = 'asc';
        break;
      case LogSortOption.outcomeSuccess:
        params['sort'] = 'outcome';
        params['outcomeOrder'] = ['SUCCESS', 'PARTIAL', 'FAILED'];
        break;
      case LogSortOption.outcomeFailed:
        params['sort'] = 'outcome';
        params['outcomeOrder'] = ['FAILED', 'PARTIAL', 'SUCCESS'];
        break;
    }

    return params;
  }
}

/// Notifier for managing log filter state
class LogFilterNotifier extends Notifier<LogFilterState> {
  @override
  LogFilterState build() {
    return const LogFilterState();
  }

  /// Toggle an outcome filter
  void toggleOutcome(LogOutcome outcome) {
    final currentOutcomes = Set<LogOutcome>.from(state.selectedOutcomes);
    if (currentOutcomes.contains(outcome)) {
      currentOutcomes.remove(outcome);
    } else {
      currentOutcomes.add(outcome);
    }
    state = state.copyWith(selectedOutcomes: currentOutcomes);
  }

  /// Set a single outcome (exclusive selection)
  void setOutcome(LogOutcome? outcome) {
    if (outcome == null) {
      state = state.copyWith(selectedOutcomes: {});
    } else {
      state = state.copyWith(selectedOutcomes: {outcome});
    }
  }

  /// Set time filter
  void setTimeFilter(LogTimeFilter filter) {
    state = state.copyWith(timeFilter: filter);
  }

  /// Set sort option
  void setSortOption(LogSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  /// Toggle "only with photos" filter
  void togglePhotosOnly() {
    state = state.copyWith(showOnlyWithPhotos: !state.showOnlyWithPhotos);
  }

  /// Clear all filters
  void clearAllFilters() {
    state = const LogFilterState();
  }

  /// Clear only outcome filters
  void clearOutcomeFilters() {
    state = state.copyWith(selectedOutcomes: {});
  }
}

/// Provider for log filter state
final logFilterProvider = NotifierProvider<LogFilterNotifier, LogFilterState>(
  LogFilterNotifier.new,
);

/// Helper provider to check if a specific outcome is selected
final isOutcomeSelectedProvider = Provider.family<bool, LogOutcome>((ref, outcome) {
  final filterState = ref.watch(logFilterProvider);
  return filterState.selectedOutcomes.isEmpty || filterState.selectedOutcomes.contains(outcome);
});
