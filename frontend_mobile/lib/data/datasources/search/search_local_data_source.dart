import 'dart:convert';
import 'package:hive/hive.dart';

/// Type of search context for separate history tracking.
enum SearchType { recipe, logPost }

/// Local data source for managing search history using Hive.
class SearchLocalDataSource {
  static const String _boxName = 'search_history_box';
  static const String _recipeHistoryKey = 'recipe_search_history';
  static const String _logPostHistoryKey = 'log_post_search_history';
  static const int _maxHistoryItems = 15;

  String _getKey(SearchType type) {
    return type == SearchType.recipe ? _recipeHistoryKey : _logPostHistoryKey;
  }

  /// Add a search term to history for a specific search type.
  /// Moves existing term to top if already present.
  Future<void> addSearchTerm(String term, SearchType type) async {
    final trimmedTerm = term.trim();
    if (trimmedTerm.isEmpty || trimmedTerm.length < 2) return;

    final box = await Hive.openBox(_boxName);
    final key = _getKey(type);

    final history = await getSearchHistory(type);

    // Remove if exists (to move to top)
    history.remove(trimmedTerm);

    // Add to front
    history.insert(0, trimmedTerm);

    // Trim to max size
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    await box.put(key, jsonEncode(history));
  }

  /// Get search history for a specific type.
  /// Returns empty list if no history exists.
  Future<List<String>> getSearchHistory(SearchType type) async {
    final box = await Hive.openBox(_boxName);
    final key = _getKey(type);
    final jsonString = box.get(key);

    if (jsonString == null) return [];

    try {
      return List<String>.from(jsonDecode(jsonString));
    } catch (e) {
      // Clear corrupted data
      await box.delete(key);
      return [];
    }
  }

  /// Remove a specific search term from history.
  Future<void> removeSearchTerm(String term, SearchType type) async {
    final box = await Hive.openBox(_boxName);
    final key = _getKey(type);

    final history = await getSearchHistory(type);
    history.remove(term);

    await box.put(key, jsonEncode(history));
  }

  /// Clear all history for a specific type.
  Future<void> clearHistory(SearchType type) async {
    final box = await Hive.openBox(_boxName);
    final key = _getKey(type);
    await box.delete(key);
  }

  /// Clear all search history (call on logout if needed).
  Future<void> clearAllHistory() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }
}
