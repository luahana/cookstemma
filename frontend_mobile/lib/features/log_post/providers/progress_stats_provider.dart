import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:pairing_planet2_frontend/core/providers/isar_provider.dart';
import 'package:pairing_planet2_frontend/data/models/local/progress_stats_entry.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/progress_overview_card.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_list_provider.dart';

class ProgressStatsLocalDataSource {
  final Isar _isar;
  static const String _statsKey = 'user_progress_stats';

  ProgressStatsLocalDataSource(this._isar);

  Future<void> saveStats({
    required int successCount,
    required int partialCount,
    required int failedCount,
    required int currentStreak,
    required int longestStreak,
    DateTime? lastLogDate,
  }) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.progressStatsEntrys
          .filter()
          .statsKeyEqualTo(_statsKey)
          .findFirst();

      final entry = ProgressStatsEntry()
        ..statsKey = _statsKey
        ..successCount = successCount
        ..partialCount = partialCount
        ..failedCount = failedCount
        ..currentStreak = currentStreak
        ..longestStreak = longestStreak
        ..lastLogDate = lastLogDate;

      if (existing != null) {
        entry.id = existing.id;
      }
      await _isar.progressStatsEntrys.put(entry);
    });
  }

  Future<ProgressStats> getStats() async {
    final entry = await _isar.progressStatsEntrys
        .filter()
        .statsKeyEqualTo(_statsKey)
        .findFirst();

    if (entry == null) {
      return const ProgressStats(
        successCount: 0,
        partialCount: 0,
        failedCount: 0,
        currentStreak: 0,
        longestStreak: 0,
        lastLogDate: null,
      );
    }

    return ProgressStats(
      successCount: entry.successCount,
      partialCount: entry.partialCount,
      failedCount: entry.failedCount,
      currentStreak: entry.currentStreak,
      longestStreak: entry.longestStreak,
      lastLogDate: entry.lastLogDate,
    );
  }

  Future<ProgressStats> updateStreak(DateTime logDate) async {
    final stats = await getStats();
    var currentStreak = stats.currentStreak;
    var longestStreak = stats.longestStreak;

    if (stats.lastLogDate != null) {
      final daysDiff = _daysBetween(stats.lastLogDate!, logDate);

      if (daysDiff == 0) {
        // Same day, streak continues but no increment
      } else if (daysDiff == 1) {
        // Consecutive day, increment streak
        currentStreak++;
      } else {
        // Streak broken, start new streak
        currentStreak = 1;
      }
    } else {
      // First log ever
      currentStreak = 1;
    }

    // Update longest streak if current is higher
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    await saveStats(
      successCount: stats.successCount,
      partialCount: stats.partialCount,
      failedCount: stats.failedCount,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastLogDate: logDate,
    );

    return await getStats();
  }

  int _daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  Future<void> checkAndResetStreak() async {
    final stats = await getStats();

    if (stats.lastLogDate != null) {
      final now = DateTime.now();
      final daysDiff = _daysBetween(stats.lastLogDate!, now);

      if (daysDiff > 1) {
        // More than a day has passed, reset streak
        await saveStats(
          successCount: stats.successCount,
          partialCount: stats.partialCount,
          failedCount: stats.failedCount,
          currentStreak: 0,
          longestStreak: stats.longestStreak,
          lastLogDate: stats.lastLogDate,
        );
      }
    }
  }
}

final progressStatsLocalDataSourceProvider =
    Provider<ProgressStatsLocalDataSource>((ref) {
  final isar = ref.read(isarProvider);
  return ProgressStatsLocalDataSource(isar);
});

class ProgressStatsNotifier extends AsyncNotifier<ProgressStats> {
  late final ProgressStatsLocalDataSource _localDataSource;

  @override
  Future<ProgressStats> build() async {
    _localDataSource = ref.read(progressStatsLocalDataSourceProvider);

    // Check if streak needs to be reset
    await _localDataSource.checkAndResetStreak();

    // Get local stats first
    final localStats = await _localDataSource.getStats();

    // Watch log list for changes
    final logListAsync = ref.watch(logPostPaginatedListProvider);

    return logListAsync.when(
      data: (logListState) {
        // Calculate stats from log list
        int successCount = 0;
        int partialCount = 0;
        int failedCount = 0;

        for (final log in logListState.items) {
          switch (log.outcome?.toUpperCase()) {
            case 'SUCCESS':
              successCount++;
              break;
            case 'PARTIAL':
              partialCount++;
              break;
            case 'FAILED':
              failedCount++;
              break;
          }
        }

        // Merge with local streak data
        return ProgressStats(
          successCount: successCount,
          partialCount: partialCount,
          failedCount: failedCount,
          currentStreak: localStats.currentStreak,
          longestStreak: localStats.longestStreak,
          lastLogDate: localStats.lastLogDate,
        );
      },
      loading: () => localStats,
      error: (error, stackTrace) => localStats,
    );
  }

  Future<void> recordNewLog(String outcome) async {
    final now = DateTime.now();
    await _localDataSource.updateStreak(now);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final progressStatsProvider =
    AsyncNotifierProvider<ProgressStatsNotifier, ProgressStats>(
  ProgressStatsNotifier.new,
);

final currentStreakProvider = Provider<int>((ref) {
  final statsAsync = ref.watch(progressStatsProvider);
  return statsAsync.valueOrNull?.currentStreak ?? 0;
});

final loggedTodayProvider = Provider<bool>((ref) {
  final statsAsync = ref.watch(progressStatsProvider);
  return statsAsync.valueOrNull?.loggedToday ?? false;
});
