import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/progress_overview_card.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_list_provider.dart';

/// Local data source for storing progress stats
class ProgressStatsLocalDataSource {
  static const String _boxName = 'progress_stats_box';
  static const String _statsKey = 'user_progress_stats';
  static const String _lastLogDateKey = 'last_log_date';
  static const String _currentStreakKey = 'current_streak';
  static const String _longestStreakKey = 'longest_streak';

  Future<Box<dynamic>> _getBox() async {
    return await Hive.openBox(_boxName);
  }

  /// Save progress stats
  Future<void> saveStats({
    required int successCount,
    required int partialCount,
    required int failedCount,
    required int currentStreak,
    required int longestStreak,
    DateTime? lastLogDate,
  }) async {
    final box = await _getBox();
    await box.put(_statsKey, {
      'successCount': successCount,
      'partialCount': partialCount,
      'failedCount': failedCount,
    });
    await box.put(_currentStreakKey, currentStreak);
    await box.put(_longestStreakKey, longestStreak);
    if (lastLogDate != null) {
      await box.put(_lastLogDateKey, lastLogDate.toIso8601String());
    }
  }

  /// Get saved progress stats
  Future<ProgressStats> getStats() async {
    final box = await _getBox();
    final stats = box.get(_statsKey) as Map<dynamic, dynamic>?;
    final currentStreak = box.get(_currentStreakKey) as int? ?? 0;
    final longestStreak = box.get(_longestStreakKey) as int? ?? 0;
    final lastLogDateStr = box.get(_lastLogDateKey) as String?;

    return ProgressStats(
      successCount: stats?['successCount'] as int? ?? 0,
      partialCount: stats?['partialCount'] as int? ?? 0,
      failedCount: stats?['failedCount'] as int? ?? 0,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastLogDate: lastLogDateStr != null ? DateTime.parse(lastLogDateStr) : null,
    );
  }

  /// Update streak after a new log
  Future<ProgressStats> updateStreak(DateTime logDate) async {
    final box = await _getBox();
    final lastLogDateStr = box.get(_lastLogDateKey) as String?;
    var currentStreak = box.get(_currentStreakKey) as int? ?? 0;
    var longestStreak = box.get(_longestStreakKey) as int? ?? 0;

    if (lastLogDateStr != null) {
      final lastLogDate = DateTime.parse(lastLogDateStr);
      final daysDiff = _daysBetween(lastLogDate, logDate);

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

    // Save updated values
    await box.put(_currentStreakKey, currentStreak);
    await box.put(_longestStreakKey, longestStreak);
    await box.put(_lastLogDateKey, logDate.toIso8601String());

    return await getStats();
  }

  /// Calculate days between two dates (ignoring time)
  int _daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  /// Check if streak should be reset (called on app open)
  Future<void> checkAndResetStreak() async {
    final box = await _getBox();
    final lastLogDateStr = box.get(_lastLogDateKey) as String?;

    if (lastLogDateStr != null) {
      final lastLogDate = DateTime.parse(lastLogDateStr);
      final now = DateTime.now();
      final daysDiff = _daysBetween(lastLogDate, now);

      if (daysDiff > 1) {
        // More than a day has passed, reset streak
        await box.put(_currentStreakKey, 0);
      }
    }
  }
}

/// Notifier for progress stats
class ProgressStatsNotifier extends AsyncNotifier<ProgressStats> {
  late final ProgressStatsLocalDataSource _localDataSource;

  @override
  Future<ProgressStats> build() async {
    _localDataSource = ProgressStatsLocalDataSource();

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
      error: (_, __) => localStats,
    );
  }

  /// Record a new log and update streak
  Future<void> recordNewLog(String outcome) async {
    final now = DateTime.now();
    await _localDataSource.updateStreak(now);
    ref.invalidateSelf();
  }

  /// Refresh stats from server
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider for progress stats
final progressStatsProvider =
    AsyncNotifierProvider<ProgressStatsNotifier, ProgressStats>(
  ProgressStatsNotifier.new,
);

/// Provider for just the current streak (for quick access)
final currentStreakProvider = Provider<int>((ref) {
  final statsAsync = ref.watch(progressStatsProvider);
  return statsAsync.valueOrNull?.currentStreak ?? 0;
});

/// Provider for checking if user logged today
final loggedTodayProvider = Provider<bool>((ref) {
  final statsAsync = ref.watch(progressStatsProvider);
  return statsAsync.valueOrNull?.loggedToday ?? false;
});
