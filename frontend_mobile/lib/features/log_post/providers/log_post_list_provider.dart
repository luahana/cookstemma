import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_providers.dart';

class LogPostListState {
  final List<LogPostSummary> items;
  final bool hasNext;
  final String? searchQuery;

  LogPostListState({
    required this.items,
    required this.hasNext,
    this.searchQuery,
  });
}

class LogPostListNotifier extends AsyncNotifier<LogPostListState> {
  int _currentPage = 0;
  bool _hasNext = true;
  bool _isFetchingNext = false;
  String? _searchQuery;

  @override
  Future<LogPostListState> build() async {
    _currentPage = 0;
    _hasNext = true;
    _searchQuery = null;
    final items = await _fetchPage(0);
    return LogPostListState(items: items, hasNext: _hasNext, searchQuery: _searchQuery);
  }

  Future<List<LogPostSummary>> _fetchPage(int page) async {
    final useCase = ref.read(getLogPostListUseCaseProvider);
    final result = await useCase(page: page, size: 20, query: _searchQuery);

    return result.fold(
      (failure) => throw failure,
      (sliceResponse) {
        _hasNext = sliceResponse.hasNext;
        return sliceResponse.content;
      },
    );
  }

  /// 검색 실행
  Future<void> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      await clearSearch();
      return;
    }

    _searchQuery = trimmedQuery;
    _currentPage = 0;
    _hasNext = true;

    state = const AsyncValue.loading();

    try {
      final items = await _fetchPage(0);
      state = AsyncValue.data(LogPostListState(
        items: items,
        hasNext: _hasNext,
        searchQuery: _searchQuery,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 검색 초기화
  Future<void> clearSearch() async {
    if (_searchQuery == null) return;

    _searchQuery = null;
    _currentPage = 0;
    _hasNext = true;

    ref.invalidateSelf();
  }

  Future<void> fetchNextPage() async {
    if (_isFetchingNext || !_hasNext) return;

    _isFetchingNext = true;
    try {
      final currentState = state.value;
      if (currentState == null) return;

      _currentPage++;
      final newItems = await _fetchPage(_currentPage);

      final allItems = [...currentState.items, ...newItems];
      final uniqueItems = <String, LogPostSummary>{};
      for (final item in allItems) {
        uniqueItems[item.id] = item;
      }

      state = AsyncValue.data(LogPostListState(
        items: uniqueItems.values.toList(),
        hasNext: _hasNext,
        searchQuery: _searchQuery,
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

final logPostPaginatedListProvider = AsyncNotifierProvider<LogPostListNotifier, LogPostListState>(() {
  return LogPostListNotifier();
});
