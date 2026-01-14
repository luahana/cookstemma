import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/features/hashtag/providers/hashtag_providers.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_providers.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';

/// Filter mode for search results.
enum SearchFilterMode {
  /// Show both recipes and logs matching the query.
  all,

  /// Show only recipes matching the query.
  recipes,

  /// Show only log posts matching the query.
  logs,

  /// Treat query as hashtag and show content tagged with it.
  hashtags,
}

/// Sealed class for unified search results (recipes or log posts).
sealed class SearchItem {
  const SearchItem();
}

class RecipeSearchItem extends SearchItem {
  final RecipeSummary recipe;
  const RecipeSearchItem(this.recipe);
}

class LogPostSearchItem extends SearchItem {
  final LogPostSummary logPost;
  const LogPostSearchItem(this.logPost);
}

/// State class for search results with pagination.
class SearchResultsState {
  final List<SearchItem> items;
  final bool hasNext;
  final String? query;
  final String? sort;
  final String? contentType;
  final SearchFilterMode filterMode;

  SearchResultsState({
    required this.items,
    required this.hasNext,
    this.query,
    this.sort,
    this.contentType,
    this.filterMode = SearchFilterMode.recipes,
  });

  SearchResultsState copyWith({
    List<SearchItem>? items,
    bool? hasNext,
    String? query,
    String? sort,
    String? contentType,
    SearchFilterMode? filterMode,
    bool clearQuery = false,
  }) {
    return SearchResultsState(
      items: items ?? this.items,
      hasNext: hasNext ?? this.hasNext,
      query: clearQuery ? null : (query ?? this.query),
      sort: sort ?? this.sort,
      contentType: contentType ?? this.contentType,
      filterMode: filterMode ?? this.filterMode,
    );
  }
}

/// Parameters for the search results provider.
class SearchParams {
  final String? sort;
  final String? contentType;
  final String? recipeId;
  final String? initialFilterMode;

  const SearchParams({
    this.sort,
    this.contentType,
    this.recipeId,
    this.initialFilterMode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchParams &&
          runtimeType == other.runtimeType &&
          sort == other.sort &&
          contentType == other.contentType &&
          recipeId == other.recipeId &&
          initialFilterMode == other.initialFilterMode;

  @override
  int get hashCode =>
      sort.hashCode ^
      contentType.hashCode ^
      recipeId.hashCode ^
      initialFilterMode.hashCode;
}

/// Provider for search results with sort, content type, and filter mode support.
/// Used by SearchScreen for View More and text search functionality.
class SearchResultsNotifier
    extends FamilyAsyncNotifier<SearchResultsState, SearchParams> {
  String? _nextCursor;
  int _currentPage = 0;
  bool _hasNext = true;
  bool _isFetchingNext = false;
  String? _currentQuery;
  String? _currentSort;
  String? _contentType;
  String? _recipeId;
  SearchFilterMode _filterMode = SearchFilterMode.recipes;

  bool get _isLogPostMode => _contentType == 'logPosts';

  @override
  Future<SearchResultsState> build(SearchParams arg) async {
    _nextCursor = null;
    _currentPage = 0;
    _hasNext = true;
    _isFetchingNext = false;
    _currentQuery = null;
    _currentSort = arg.sort;
    _contentType = arg.contentType;
    _recipeId = arg.recipeId;
    _filterMode = _parseFilterMode(arg.initialFilterMode);

    // View More mode: fetch immediately if sort or contentType provided
    if (_shouldFetchInitially(arg)) {
      final items = await _fetchItems(cursor: null, page: 0);
      return SearchResultsState(
        items: items,
        hasNext: _hasNext,
        sort: arg.sort,
        contentType: arg.contentType,
        filterMode: _filterMode,
      );
    }

    // Otherwise, start with empty state (user will type a query)
    return SearchResultsState(
      items: [],
      hasNext: false,
      sort: arg.sort,
      contentType: arg.contentType,
      filterMode: _filterMode,
    );
  }

  SearchFilterMode _parseFilterMode(String? mode) {
    if (mode == null) return SearchFilterMode.recipes;
    return switch (mode.toLowerCase()) {
      'logs' => SearchFilterMode.logs,
      'hashtags' => SearchFilterMode.hashtags,
      _ => SearchFilterMode.recipes,
    };
  }

  bool _shouldFetchInitially(SearchParams arg) {
    // Fetch if sort is provided (recipe View More)
    if (arg.sort != null && arg.sort!.isNotEmpty) return true;
    // Fetch if contentType is logPosts (log post View More)
    if (arg.contentType == 'logPosts') return true;
    // Auto-fetch for recipes/logs filter mode (browse mode)
    // Skip hashtags - requires query which is handled by screen's initState
    if (arg.initialFilterMode != null && arg.initialFilterMode != 'hashtags') {
      return true;
    }
    return false;
  }

  Future<List<SearchItem>> _fetchItems({
    String? cursor,
    int? page,
    String? query,
  }) async {
    // Handle filter modes
    switch (_filterMode) {
      case SearchFilterMode.recipes:
        return _fetchRecipes(cursor: cursor, query: query);
      case SearchFilterMode.logs:
        return _fetchLogPosts(cursor: cursor, page: page, query: query);
      case SearchFilterMode.hashtags:
        return _fetchByHashtag(cursor: cursor, query: query);
      case SearchFilterMode.all:
        // Default behavior based on contentType
        if (_isLogPostMode) {
          return _fetchLogPosts(cursor: cursor, page: page, query: query);
        }
        return _fetchRecipes(cursor: cursor, query: query);
    }
  }

  Future<List<SearchItem>> _fetchRecipes({
    String? cursor,
    String? query,
  }) async {
    final repository = ref.read(recipeRepositoryProvider);
    final result = await repository.getRecipes(
      cursor: cursor,
      size: 20,
      query: query,
      sort: _currentSort,
    );

    return result.fold((failure) => throw failure, (response) {
      _hasNext = response.hasNext;
      _nextCursor = response.nextCursor;
      return response.content.map((r) => RecipeSearchItem(r)).toList();
    });
  }

  Future<List<SearchItem>> _fetchLogPosts({
    String? cursor,
    int? page,
    String? query,
  }) async {
    final repository = ref.read(logPostRepositoryProvider);

    // Recipe-specific logs use page-based pagination
    if (_recipeId != null && _recipeId!.isNotEmpty) {
      final result = await repository.getLogsByRecipe(
        recipeId: _recipeId!,
        page: page ?? _currentPage,
        size: 20,
      );

      return result.fold((failure) => throw failure, (response) {
        _hasNext = !response.last;
        _currentPage = (page ?? _currentPage) + 1;
        return response.content.map((l) => LogPostSearchItem(l)).toList();
      });
    }

    // General log posts use cursor-based pagination
    final result = await repository.getLogPosts(
      cursor: cursor,
      size: 20,
      query: query,
    );

    return result.fold((failure) => throw failure, (response) {
      _hasNext = response.hasNext;
      _nextCursor = response.nextCursor;
      return response.content.map((l) => LogPostSearchItem(l)).toList();
    });
  }

  /// Fetch content by hashtag (recipes first, then logs).
  Future<List<SearchItem>> _fetchByHashtag({
    String? cursor,
    String? query,
  }) async {
    if (query == null || query.isEmpty) return [];

    // Normalize hashtag (remove # prefix if present)
    final hashtagName = query.replaceFirst('#', '').toLowerCase().trim();
    if (hashtagName.isEmpty) return [];

    final hashtagRepository = ref.read(hashtagRepositoryProvider);
    final items = <SearchItem>[];

    // Fetch recipes with hashtag
    final recipesResult = await hashtagRepository.getRecipesByHashtag(
      hashtagName: hashtagName,
      cursor: cursor,
      size: 20,
    );

    recipesResult.fold(
      (failure) => throw failure,
      (response) {
        _hasNext = response.hasNext;
        _nextCursor = response.nextCursor;
        items.addAll(response.content.map((r) => RecipeSearchItem(r)));
      },
    );

    // On first page, also fetch log posts with hashtag
    if (cursor == null) {
      final logsResult = await hashtagRepository.getLogPostsByHashtag(
        hashtagName: hashtagName,
        cursor: null,
        size: 20,
      );

      logsResult.fold(
        (failure) {}, // Don't throw, just skip logs if they fail
        (response) {
          items.addAll(response.content.map((l) => LogPostSearchItem(l)));
        },
      );
    }

    return items;
  }

  /// Change the filter mode and re-fetch results.
  Future<void> setFilterMode(SearchFilterMode mode) async {
    if (_filterMode == mode) return;

    _filterMode = mode;
    _nextCursor = null;
    _currentPage = 0;
    _hasNext = true;

    // Re-fetch with current query if exists
    if (_currentQuery != null && _currentQuery!.isNotEmpty) {
      state = const AsyncValue.loading();
      try {
        final items = await _fetchItems(
          cursor: null,
          page: 0,
          query: _currentQuery,
        );
        state = AsyncValue.data(SearchResultsState(
          items: items,
          hasNext: _hasNext,
          query: _currentQuery,
          sort: _currentSort,
          contentType: _contentType,
          filterMode: _filterMode,
        ));
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    } else {
      // No query, show empty state with new filter mode
      state = AsyncValue.data(SearchResultsState(
        items: [],
        hasNext: false,
        sort: _currentSort,
        contentType: _contentType,
        filterMode: _filterMode,
      ));
    }
  }

  /// Execute search with query text.
  Future<void> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      await clearSearch();
      return;
    }

    _currentQuery = trimmedQuery;
    _nextCursor = null;
    _currentPage = 0;
    _hasNext = true;

    state = const AsyncValue.loading();

    try {
      final items = await _fetchItems(
        cursor: null,
        page: 0,
        query: trimmedQuery,
      );
      state = AsyncValue.data(SearchResultsState(
        items: items,
        hasNext: _hasNext,
        query: _currentQuery,
        sort: _currentSort,
        contentType: _contentType,
        filterMode: _filterMode,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Clear search and reload with sort/contentType only (if available).
  Future<void> clearSearch() async {
    if (_currentQuery == null && _currentSort == null && !_isLogPostMode) {
      return;
    }

    _currentQuery = null;
    _nextCursor = null;
    _currentPage = 0;
    _hasNext = true;

    // If in View More mode, reload without query
    if (_currentSort != null || _isLogPostMode) {
      state = const AsyncValue.loading();
      try {
        final items = await _fetchItems(cursor: null, page: 0);
        state = AsyncValue.data(SearchResultsState(
          items: items,
          hasNext: _hasNext,
          sort: _currentSort,
          contentType: _contentType,
          filterMode: _filterMode,
        ));
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    } else {
      // No sort or contentType, show empty state
      state = AsyncValue.data(SearchResultsState(
        items: [],
        hasNext: false,
        contentType: _contentType,
        filterMode: _filterMode,
      ));
    }
  }

  /// Fetch next page of results.
  Future<void> fetchNextPage() async {
    if (_isFetchingNext || !_hasNext) return;

    _isFetchingNext = true;

    try {
      final items = await _fetchItems(
        cursor: _nextCursor,
        page: _currentPage,
        query: _currentQuery,
      );

      _isFetchingNext = false;

      final previousState = state.value;
      final previousItems = previousState?.items ?? [];

      state = AsyncValue.data(
        SearchResultsState(
          items: [...previousItems, ...items],
          hasNext: _hasNext,
          query: _currentQuery,
          sort: _currentSort,
          contentType: _contentType,
          filterMode: _filterMode,
        ),
      );
    } catch (e) {
      _isFetchingNext = false;
    }
  }
}

final searchResultsProvider = AsyncNotifierProvider.family<
    SearchResultsNotifier, SearchResultsState, SearchParams>(
  SearchResultsNotifier.new,
);
