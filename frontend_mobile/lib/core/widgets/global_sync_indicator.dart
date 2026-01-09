import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/log_sync_engine.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/sync_queue_local_data_source.dart';

/// Global sync indicator that shows in top-right of main screens
/// Displays sync status with animated cloud icon
class GlobalSyncIndicator extends ConsumerWidget {
  const GlobalSyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(syncQueueStatsProvider);

    return statsAsync.when(
      data: (stats) {
        // Hide when everything is synced
        if (!stats.hasUnsyncedItems && stats.syncing == 0) {
          return const SizedBox.shrink();
        }

        return _SyncIndicatorContent(stats: stats);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SyncIndicatorContent extends StatefulWidget {
  final SyncQueueStats stats;

  const _SyncIndicatorContent({required this.stats});

  @override
  State<_SyncIndicatorContent> createState() => _SyncIndicatorContentState();
}

class _SyncIndicatorContentState extends State<_SyncIndicatorContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _updateAnimation();
  }

  @override
  void didUpdateWidget(_SyncIndicatorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
  }

  void _updateAnimation() {
    if (widget.stats.syncing > 0) {
      _controller.repeat();
    } else if (widget.stats.hasUnsyncedItems) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSyncing = widget.stats.syncing > 0;
    final hasFailed = widget.stats.failed > 0;
    final pendingCount = widget.stats.needsSync;

    // Determine icon and color based on state
    final iconColor = hasFailed ? AppColors.error : AppColors.primary;
    final bgColor = hasFailed
        ? AppColors.error.withValues(alpha: 0.1)
        : AppColors.primary.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: () => _showSyncDetails(context),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: isSyncing ? 1.0 : _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cloud icon with sync animation
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        hasFailed ? Icons.cloud_off : Icons.cloud_done,
                        color: iconColor,
                        size: 20,
                      ),
                      if (isSyncing)
                        Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: Icon(
                            Icons.sync,
                            color: iconColor,
                            size: 14,
                          ),
                        ),
                    ],
                  ),
                  // Badge count
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pendingCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSyncDetails(BuildContext context) {
    final stats = widget.stats;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sync Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Pending', stats.pending, AppColors.primary),
            _buildStatRow('Syncing', stats.syncing, AppColors.growth),
            _buildStatRow('Failed', stats.failed, AppColors.error),
            const SizedBox(height: 16),
            Text(
              stats.hasUnsyncedItems
                  ? 'Your data will sync automatically when connected.'
                  : 'All data is synced!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          const Spacer(),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: count > 0 ? color : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
