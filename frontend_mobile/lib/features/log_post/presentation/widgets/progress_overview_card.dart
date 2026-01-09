import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/outcome_badge.dart';

/// Stats for the progress overview
class ProgressStats {
  final int successCount;
  final int partialCount;
  final int failedCount;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastLogDate;

  const ProgressStats({
    this.successCount = 0,
    this.partialCount = 0,
    this.failedCount = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastLogDate,
  });

  int get totalCount => successCount + partialCount + failedCount;

  double get successRate =>
      totalCount > 0 ? successCount / totalCount : 0.0;

  bool get hasLogs => totalCount > 0;

  /// Check if user logged today
  bool get loggedToday {
    if (lastLogDate == null) return false;
    final now = DateTime.now();
    return lastLogDate!.year == now.year &&
        lastLogDate!.month == now.month &&
        lastLogDate!.day == now.day;
  }
}

/// Card showing cooking progress overview with stats
class ProgressOverviewCard extends StatelessWidget {
  final ProgressStats stats;
  final VoidCallback? onTap;

  const ProgressOverviewCard({
    super.key,
    required this.stats,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'logPost.progress.overview'.tr(),
      child: GestureDetector(
        onTap: onTap != null
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with streak
              _buildHeader(),
              const SizedBox(height: 20),
              // Outcome stats row
              _buildOutcomeStats(),
              if (stats.hasLogs) ...[
                const SizedBox(height: 16),
                // Progress bar
                _buildProgressBar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'logPost.progress.yourJourney'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stats.hasLogs
                    ? 'logPost.progress.totalLogs'.tr(namedArgs: {'count': stats.totalCount.toString()})
                    : 'logPost.progress.startLogging'.tr(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Streak badge
        if (stats.currentStreak > 0) _buildStreakBadge(),
      ],
    );
  }

  Widget _buildStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange[400],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '${stats.currentStreak}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeStats() {
    return Row(
      children: [
        _buildStatItem(
          emoji: LogOutcome.success.emoji,
          count: stats.successCount,
          label: 'logPost.progress.wins'.tr(),
          color: LogOutcome.success.primaryColor,
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          emoji: LogOutcome.partial.emoji,
          count: stats.partialCount,
          label: 'logPost.progress.learning'.tr(),
          color: LogOutcome.partial.primaryColor,
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          emoji: LogOutcome.failed.emoji,
          count: stats.failedCount,
          label: 'logPost.progress.lessons'.tr(),
          color: LogOutcome.failed.primaryColor,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String emoji,
    required int count,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final total = stats.totalCount;
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'logPost.progress.successRate'.tr(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            Text(
              '${(stats.successRate * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                if (stats.successCount > 0)
                  Flexible(
                    flex: stats.successCount,
                    child: Container(color: LogOutcome.success.primaryColor),
                  ),
                if (stats.partialCount > 0)
                  Flexible(
                    flex: stats.partialCount,
                    child: Container(color: LogOutcome.partial.primaryColor),
                  ),
                if (stats.failedCount > 0)
                  Flexible(
                    flex: stats.failedCount,
                    child: Container(color: LogOutcome.failed.primaryColor),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact version for inline use
class CompactProgressStats extends StatelessWidget {
  final ProgressStats stats;

  const CompactProgressStats({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactStat(LogOutcome.success.emoji, stats.successCount),
        const SizedBox(width: 12),
        _buildCompactStat(LogOutcome.partial.emoji, stats.partialCount),
        const SizedBox(width: 12),
        _buildCompactStat(LogOutcome.failed.emoji, stats.failedCount),
        if (stats.currentStreak > 0) ...[
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 2),
                Text(
                  '${stats.currentStreak}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactStat(String emoji, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Streak celebration widget
class StreakCelebration extends StatelessWidget {
  final int streak;
  final VoidCallback? onDismiss;

  const StreakCelebration({
    super.key,
    required this.streak,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    String emoji;

    if (streak >= 30) {
      message = 'logPost.streak.legendary'.tr();
      emoji = '👑';
    } else if (streak >= 14) {
      message = 'logPost.streak.amazing'.tr();
      emoji = '🌟';
    } else if (streak >= 7) {
      message = 'logPost.streak.great'.tr();
      emoji = '🔥';
    } else if (streak >= 3) {
      message = 'logPost.streak.nice'.tr();
      emoji = '✨';
    } else {
      message = 'logPost.streak.started'.tr();
      emoji = '🎯';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[400]!, Colors.deepOrange[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak ${streak == 1 ? 'day' : 'days'} streak!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
