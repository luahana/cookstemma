import 'package:isar/isar.dart';

part 'search_history_entry.g.dart';

@collection
class SearchHistoryEntry {
  Id id = Isar.autoIncrement;

  @Index()
  late String searchType;

  @Index()
  late String term;

  late DateTime searchedAt;
}
