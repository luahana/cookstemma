import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/data/datasources/search/search_local_data_source.dart';

/// Provider for the search local data source.
final searchLocalDataSourceProvider = Provider(
  (ref) => SearchLocalDataSource(),
);

/// Provider for recipe search history.
final recipeSearchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>(
  (ref) => SearchHistoryNotifier(ref, SearchType.recipe),
);

/// Provider for log post search history.
final logPostSearchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>(
  (ref) => SearchHistoryNotifier(ref, SearchType.logPost),
);

/// StateNotifier for managing search history.
class SearchHistoryNotifier extends StateNotifier<List<String>> {
  final Ref _ref;
  final SearchType _type;

  SearchHistoryNotifier(this._ref, this._type) : super([]) {
    _loadHistory();
  }

  /// Load history from local storage.
  Future<void> _loadHistory() async {
    final dataSource = _ref.read(searchLocalDataSourceProvider);
    state = await dataSource.getSearchHistory(_type);
  }

  /// Add a search term to history.
  Future<void> addSearch(String term) async {
    if (term.trim().isEmpty) return;

    final dataSource = _ref.read(searchLocalDataSourceProvider);
    await dataSource.addSearchTerm(term.trim(), _type);
    await _loadHistory();
  }

  /// Remove a specific search term from history.
  Future<void> removeSearch(String term) async {
    final dataSource = _ref.read(searchLocalDataSourceProvider);
    await dataSource.removeSearchTerm(term, _type);
    await _loadHistory();
  }

  /// Clear all history.
  Future<void> clearAll() async {
    final dataSource = _ref.read(searchLocalDataSourceProvider);
    await dataSource.clearHistory(_type);
    state = [];
  }

  /// Get suggestions based on current query.
  /// If query is empty, returns recent searches (up to 5).
  /// Otherwise filters history to match query.
  List<String> getSuggestions(String query) {
    if (query.isEmpty) {
      return state.take(5).toList();
    }

    final lowerQuery = query.toLowerCase();
    return state
        .where((term) => term.toLowerCase().contains(lowerQuery))
        .take(5)
        .toList();
  }
}
