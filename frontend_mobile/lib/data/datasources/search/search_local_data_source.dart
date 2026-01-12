import 'package:isar/isar.dart';
import 'package:pairing_planet2_frontend/data/models/local/search_history_entry.dart';

enum SearchType { recipe, logPost }

class SearchLocalDataSource {
  final Isar _isar;
  static const int _maxHistoryItems = 15;

  SearchLocalDataSource(this._isar);

  String _getTypeString(SearchType type) {
    return type == SearchType.recipe ? 'recipe' : 'logPost';
  }

  Future<void> addSearchTerm(String term, SearchType type) async {
    final trimmedTerm = term.trim();
    if (trimmedTerm.isEmpty || trimmedTerm.length < 2) return;

    final typeString = _getTypeString(type);

    await _isar.writeTxn(() async {
      await _isar.searchHistoryEntrys
          .filter()
          .searchTypeEqualTo(typeString)
          .termEqualTo(trimmedTerm)
          .deleteAll();

      final entry = SearchHistoryEntry()
        ..searchType = typeString
        ..term = trimmedTerm
        ..searchedAt = DateTime.now();

      await _isar.searchHistoryEntrys.put(entry);

      final allEntries = await _isar.searchHistoryEntrys
          .filter()
          .searchTypeEqualTo(typeString)
          .sortBySearchedAtDesc()
          .findAll();

      if (allEntries.length > _maxHistoryItems) {
        final entriesToDelete = allEntries.sublist(_maxHistoryItems);
        await _isar.searchHistoryEntrys
            .deleteAll(entriesToDelete.map((e) => e.id).toList());
      }
    });
  }

  Future<List<String>> getSearchHistory(SearchType type) async {
    final typeString = _getTypeString(type);

    final entries = await _isar.searchHistoryEntrys
        .filter()
        .searchTypeEqualTo(typeString)
        .sortBySearchedAtDesc()
        .limit(_maxHistoryItems)
        .findAll();

    return entries.map((e) => e.term).toList();
  }

  Future<void> removeSearchTerm(String term, SearchType type) async {
    final typeString = _getTypeString(type);

    await _isar.writeTxn(() async {
      await _isar.searchHistoryEntrys
          .filter()
          .searchTypeEqualTo(typeString)
          .termEqualTo(term)
          .deleteAll();
    });
  }

  Future<void> clearHistory(SearchType type) async {
    final typeString = _getTypeString(type);

    await _isar.writeTxn(() async {
      await _isar.searchHistoryEntrys
          .filter()
          .searchTypeEqualTo(typeString)
          .deleteAll();
    });
  }

  Future<void> clearAllHistory() async {
    await _isar.writeTxn(() async {
      await _isar.searchHistoryEntrys.clear();
    });
  }
}
