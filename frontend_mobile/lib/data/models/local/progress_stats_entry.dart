import 'package:isar/isar.dart';

part 'progress_stats_entry.g.dart';

@collection
class ProgressStatsEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String statsKey;

  int successCount = 0;
  int partialCount = 0;
  int failedCount = 0;
  int currentStreak = 0;
  int longestStreak = 0;
  DateTime? lastLogDate;
}
