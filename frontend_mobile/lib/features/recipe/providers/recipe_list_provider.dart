import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/browse_filter_provider.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';
import '../../../domain/entities/recipe/recipe_summary.dart';

/// State class for recipe list with cursor-based pagination, cache info, search, and filters.
class RecipeListState {
  final List<RecipeSummary> items;
  final bool hasNext;
  final bool isFromCache;
  final DateTime? cachedAt;
  final String? searchQuery;
  final BrowseFilterState? filterState;

  RecipeListState({
    required this.items,
    required this.hasNext,
    this.isFromCache = false,
    this.cachedAt,
    this.searchQuery,
    this.filterState,
  });

  RecipeListState copyWith({
    List<RecipeSummary>? items,
    bool? hasNext,
    bool? isFromCache,
    DateTime? cachedAt,
    String? searchQuery,
    bool clearSearchQuery = false,
    BrowseFilterState? filterState,
  }) {
    return RecipeListState(
      items: items ?? this.items,
      hasNext: hasNext ?? this.hasNext,
      isFromCache: isFromCache ?? this.isFromCache,
      cachedAt: cachedAt ?? this.cachedAt,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      filterState: filterState ?? this.filterState,
    );
  }
}

class RecipeListNotifier extends AsyncNotifier<RecipeListState> {
  String? _nextCursor;
  bool _hasNext = true;
  bool _isFetchingNext = false;
  bool _isFromCache = false;
  DateTime? _cachedAt;
  String? _searchQuery;
  BrowseFilterState? _lastFilterState;

  @override
  Future<RecipeListState> build() async {
    // Watch filter state changes and rebuild when they change
    final filterState = ref.watch(browseFilterProvider);

    // 초기화 로직
    _nextCursor = null;
    _hasNext = true;
    _isFetchingNext = false;
    _isFromCache = false;
    _cachedAt = null;
    _lastFilterState = filterState;

    final items = await _fetchRecipes(cursor: null, filterState: filterState);
    return RecipeListState(
      items: items,
      hasNext: _hasNext,
      isFromCache: _isFromCache,
      cachedAt: _cachedAt,
      searchQuery: _searchQuery,
      filterState: filterState,
    );
  }

  Future<List<RecipeSummary>> _fetchRecipes({
    String? cursor,
    BrowseFilterState? filterState,
  }) async {
    final repository = ref.read(recipeRepositoryProvider);
    final filters = filterState ?? _lastFilterState;

    // Convert filter state to API parameters
    String? typeFilter;
    if (filters?.typeFilter == RecipeTypeFilter.originals) {
      typeFilter = 'original';
    } else if (filters?.typeFilter == RecipeTypeFilter.variants) {
      typeFilter = 'variant';
    }

    final result = await repository.getRecipes(
      cursor: cursor,
      size: 20,
      query: _searchQuery,
      cuisineFilter: filters?.cuisineFilter,
      typeFilter: typeFilter,
    );

    return result.fold((failure) => throw failure, (response) {
      _hasNext = response.hasNext;
      _nextCursor = response.nextCursor;
      // Track cache status for initial page (only when not searching/filtering)
      final hasActiveFilters = _searchQuery != null ||
          filters?.cuisineFilter != null ||
          typeFilter != null;
      if (cursor == null && !hasActiveFilters) {
        _isFromCache = response.isFromCache;
        _cachedAt = response.cachedAt;
      }
      return response.content;
    });
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
    _isFromCache = false;
    _cachedAt = null;

    state = const AsyncValue.loading();

    try {
      final items = await _fetchRecipes(cursor: null);
      state = AsyncValue.data(RecipeListState(
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
    _nextCursor = null;
    _hasNext = true;
    _isFromCache = false;
    _cachedAt = null;

    ref.invalidateSelf();
  }

  /// Pull-to-refresh: uses ref.invalidateSelf() for atomic state management.
  Future<void> refresh() async {
    _nextCursor = null;
    _hasNext = true;
    _isFromCache = false;
    _cachedAt = null;
    ref.invalidateSelf();
  }

  /// 다음 페이지 로드 (cursor-based)
  Future<void> fetchNextPage() async {
    if (_isFetchingNext || !_hasNext) return;

    _isFetchingNext = true;

    // Get current filter state
    final filters = _lastFilterState;

    // Convert filter state to API parameters
    String? typeFilter;
    if (filters?.typeFilter == RecipeTypeFilter.originals) {
      typeFilter = 'original';
    } else if (filters?.typeFilter == RecipeTypeFilter.variants) {
      typeFilter = 'variant';
    }

    final result = await ref.read(recipeRepositoryProvider).getRecipes(
          cursor: _nextCursor,
          size: 20,
          query: _searchQuery,
          cuisineFilter: filters?.cuisineFilter,
          typeFilter: typeFilter,
        );

    result.fold(
      (failure) {
        _isFetchingNext = false;
      },
      (response) {
        _nextCursor = response.nextCursor;
        _hasNext = response.hasNext;
        _isFetchingNext = false;

        final previousState = state.value;
        final previousItems = previousState?.items ?? [];

        state = AsyncValue.data(
          RecipeListState(
            items: [...previousItems, ...response.content],
            hasNext: _hasNext,
            searchQuery: _searchQuery,
            filterState: filters,
          ),
        );
      },
    );
  }
}

final recipeListProvider =
    AsyncNotifierProvider<RecipeListNotifier, RecipeListState>(
      RecipeListNotifier.new,
    );
