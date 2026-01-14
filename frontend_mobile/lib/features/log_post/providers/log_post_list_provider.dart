import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/log_sync_engine.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_providers.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_filter_provider.dart';

class LogPostListState {
  final List<LogPostSummary> items;
  final bool hasNext;
  final String? searchQuery;
  final LogFilterState? filterState;
  final String? recipeId;

  LogPostListState({
    required this.items,
    required this.hasNext,
    this.searchQuery,
    this.filterState,
    this.recipeId,
  });
}

class LogPostListNotifier extends AsyncNotifier<LogPostListState> {
  String? _nextCursor;
  bool _hasNext = true;
  bool _isFetchingNext = false;
  String? _searchQuery;

  @override
  Future<LogPostListState> build() async {
    // Watch filter state to rebuild when filters change
    final filterState = ref.watch(logFilterProvider);

    _nextCursor = null;
    _hasNext = true;
    _searchQuery = null;

    // Fetch server items
    final serverItems = await _fetchItems(null, filterState);

    // Fetch pending items for optimistic display (no search query = show pending)
    final pendingItems = await _fetchPendingItems();

    // Combine: pending items first, then server items
    final combinedItems = [...pendingItems, ...serverItems];

    return LogPostListState(
      items: combinedItems,
      hasNext: _hasNext,
      searchQuery: _searchQuery,
      filterState: filterState,
    );
  }

  /// Fetch pending log posts from sync queue for optimistic UI
  Future<List<LogPostSummary>> _fetchPendingItems() async {
    try {
      final syncQueue = ref.read(syncQueueRepositoryProvider);
      final pendingItems = await syncQueue.getPendingLogPosts();

      // Convert to LogPostSummary
      return pendingItems
          .map((item) => LogPostSummary.fromSyncQueueItem(item))
          .toList();
    } catch (e) {
      // If sync queue fails, just return empty list
      return [];
    }
  }

  Future<List<LogPostSummary>> _fetchItems(String? cursor, [LogFilterState? filterState]) async {
    final useCase = ref.read(getLogPostListUseCaseProvider);

    // Get outcomes filter
    List<String>? outcomes;
    if (filterState != null && filterState.selectedOutcomes.isNotEmpty) {
      outcomes = filterState.selectedOutcomes.map((o) => o.value).toList();
    }

    final result = await useCase(
      cursor: cursor,
      size: 20,
      query: _searchQuery,
      outcomes: outcomes,
    );

    return result.fold(
      (failure) => throw failure,
      (response) {
        _hasNext = response.hasNext;
        _nextCursor = response.nextCursor;
        // Apply client-side filtering for time and photos (if API doesn't support)
        var items = response.content;
        if (filterState != null) {
          items = _applyClientSideFilters(items, filterState);
        }
        return items;
      },
    );
  }

  /// Apply client-side filters for features not supported by API
  List<LogPostSummary> _applyClientSideFilters(
    List<LogPostSummary> items,
    LogFilterState filterState,
  ) {
    // Note: These filters are applied client-side as a fallback
    // Ideally, they should be implemented server-side for better performance

    // For now, return items as-is since the API filtering handles outcomes
    // Time filtering and photo filtering can be added here when needed
    return items;
  }

  /// 검색 실행
  Future<void> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      await clearSearch();
      return;
    }

    _searchQuery = trimmedQuery;
    _nextCursor = null;
    _hasNext = true;

    state = const AsyncValue.loading();

    try {
      final filterState = ref.read(logFilterProvider);
      // Only fetch server items during search (no pending items)
      final items = await _fetchItems(null, filterState);
      state = AsyncValue.data(LogPostListState(
        items: items,
        hasNext: _hasNext,
        searchQuery: _searchQuery,
        filterState: filterState,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 검색 초기화
  Future<void> clearSearch() async {
    if (_searchQuery == null) return;

    _searchQuery = null;
    _nextCursor = null;
    _hasNext = true;

    ref.invalidateSelf();
  }

  Future<void> fetchNextPage() async {
    if (_isFetchingNext || !_hasNext) return;

    _isFetchingNext = true;
    try {
      final currentState = state.value;
      if (currentState == null) return;

      final filterState = ref.read(logFilterProvider);
      final newItems = await _fetchItems(_nextCursor, filterState);

      final allItems = [...currentState.items, ...newItems];
      final uniqueItems = <String, LogPostSummary>{};
      for (final item in allItems) {
        uniqueItems[item.id] = item;
      }

      state = AsyncValue.data(LogPostListState(
        items: uniqueItems.values.toList(),
        hasNext: _hasNext,
        searchQuery: _searchQuery,
        filterState: filterState,
      ));
    } finally {
      _isFetchingNext = false;
    }
  }

  Future<void> refresh() async {
    _nextCursor = null;
    _hasNext = true;
    ref.invalidateSelf();
  }

  /// Refresh when filters change
  void onFiltersChanged() {
    _nextCursor = null;
    _hasNext = true;
    ref.invalidateSelf();
  }
}

final logPostPaginatedListProvider = AsyncNotifierProvider<LogPostListNotifier, LogPostListState>(() {
  return LogPostListNotifier();
});

/// Provider for logs filtered by recipe (used by "See More" from recipe detail)
class RecipeLogsNotifier extends AutoDisposeFamilyAsyncNotifier<LogPostListState, String> {
  int _currentPage = 0;
  bool _hasNext = true;
  bool _isFetchingNext = false;

  @override
  Future<LogPostListState> build(String recipeId) async {
    _currentPage = 0;
    _hasNext = true;

    final items = await _fetchPage(0, recipeId);
    return LogPostListState(
      items: items,
      hasNext: _hasNext,
      recipeId: recipeId,
    );
  }

  Future<List<LogPostSummary>> _fetchPage(int page, String recipeId) async {
    final useCase = ref.read(getLogPostListUseCaseProvider);
    final result = await useCase.getByRecipe(
      recipeId: recipeId,
      page: page,
      size: 20,
    );

    return result.fold(
      (failure) => throw failure,
      (sliceResponse) {
        _hasNext = sliceResponse.hasNext;
        return sliceResponse.content;
      },
    );
  }

  Future<void> fetchNextPage() async {
    if (_isFetchingNext || !_hasNext) return;

    final recipeId = arg;
    _isFetchingNext = true;
    try {
      final currentState = state.value;
      if (currentState == null) return;

      _currentPage++;
      final newItems = await _fetchPage(_currentPage, recipeId);

      final allItems = [...currentState.items, ...newItems];
      final uniqueItems = <String, LogPostSummary>{};
      for (final item in allItems) {
        uniqueItems[item.id] = item;
      }

      state = AsyncValue.data(LogPostListState(
        items: uniqueItems.values.toList(),
        hasNext: _hasNext,
        recipeId: recipeId,
      ));
    } finally {
      _isFetchingNext = false;
    }
  }

  Future<void> refresh() async {
    _currentPage = 0;
    _hasNext = true;
    ref.invalidateSelf();
  }
}

final recipeLogsProvider = AsyncNotifierProvider.autoDispose
    .family<RecipeLogsNotifier, LogPostListState, String>(() {
  return RecipeLogsNotifier();
});
