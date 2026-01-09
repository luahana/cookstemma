import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/outcome_badge.dart';

/// Illustrated empty state for when there are no log posts
class LogEmptyState extends StatelessWidget {
  final VoidCallback? onStartLogging;
  final EmptyStateType type;

  const LogEmptyState({
    super.key,
    this.onStartLogging,
    this.type = EmptyStateType.noLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            _buildIllustration(),
            const SizedBox(height: 32),
            // Title
            Text(
              _getTitle(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              _getDescription(),
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // CTA button
            if (onStartLogging != null) _buildCTAButton(),
            // Tips section
            if (type == EmptyStateType.noLogs) ...[
              const SizedBox(height: 40),
              _buildTipsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    switch (type) {
      case EmptyStateType.noLogs:
        return _NoLogsIllustration();
      case EmptyStateType.noFilterResults:
        return _NoResultsIllustration();
      case EmptyStateType.offline:
        return _OfflineIllustration();
    }
  }

  String _getTitle() {
    switch (type) {
      case EmptyStateType.noLogs:
        return 'logPost.empty.noLogs.title'.tr();
      case EmptyStateType.noFilterResults:
        return 'logPost.empty.noResults.title'.tr();
      case EmptyStateType.offline:
        return 'logPost.empty.offline.title'.tr();
    }
  }

  String _getDescription() {
    switch (type) {
      case EmptyStateType.noLogs:
        return 'logPost.empty.noLogs.description'.tr();
      case EmptyStateType.noFilterResults:
        return 'logPost.empty.noResults.description'.tr();
      case EmptyStateType.offline:
        return 'logPost.empty.offline.description'.tr();
    }
  }

  Widget _buildCTAButton() {
    return FilledButton.icon(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onStartLogging?.call();
      },
      icon: const Icon(Icons.camera_alt_rounded),
      label: Text('logPost.empty.startLogging'.tr()),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'logPost.empty.tips.title'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip(
            emoji: LogOutcome.success.emoji,
            text: 'logPost.empty.tips.success'.tr(),
          ),
          const SizedBox(height: 8),
          _buildTip(
            emoji: LogOutcome.partial.emoji,
            text: 'logPost.empty.tips.partial'.tr(),
          ),
          const SizedBox(height: 8),
          _buildTip(
            emoji: LogOutcome.failed.emoji,
            text: 'logPost.empty.tips.failed'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildTip({required String emoji, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

enum EmptyStateType {
  noLogs,
  noFilterResults,
  offline,
}

/// Illustration for no logs state
class _NoLogsIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
          ),
          // Pot illustration
          Positioned(
            bottom: 20,
            child: Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
            ),
          ),
          // Steam lines
          Positioned(
            top: 20,
            left: 60,
            child: _buildSteamLine(),
          ),
          Positioned(
            top: 30,
            left: 90,
            child: _buildSteamLine(),
          ),
          Positioned(
            top: 15,
            left: 120,
            child: _buildSteamLine(),
          ),
          // Camera icon
          Positioned(
            top: 10,
            right: 30,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          // Emoji faces at bottom
          Positioned(
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(LogOutcome.success.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(LogOutcome.partial.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(LogOutcome.failed.emoji, style: const TextStyle(fontSize: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteamLine() {
    return Container(
      width: 3,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Illustration for no filter results
class _NoResultsIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.orange[50],
              shape: BoxShape.circle,
            ),
          ),
          // Search icon with X
          Icon(
            Icons.search_off,
            size: 60,
            color: Colors.orange[300],
          ),
          // Filter chips floating around
          Positioned(
            top: 10,
            left: 10,
            child: _buildMiniChip(LogOutcome.success.emoji),
          ),
          Positioned(
            top: 30,
            right: 10,
            child: _buildMiniChip(LogOutcome.partial.emoji),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: _buildMiniChip(LogOutcome.failed.emoji),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(String emoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 14)),
    );
  }
}

/// Illustration for offline state
class _OfflineIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
          ),
          // Cloud with X
          Icon(
            Icons.cloud_off,
            size: 60,
            color: Colors.grey[400],
          ),
          // Pending indicator
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.orange[600]),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'logPost.empty.offline.pending'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter-specific empty state
class FilterEmptyState extends StatelessWidget {
  final VoidCallback onClearFilters;

  const FilterEmptyState({
    super.key,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NoResultsIllustration(),
            const SizedBox(height: 24),
            Text(
              'logPost.empty.noResults.title'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'logPost.empty.noResults.tryDifferent'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onClearFilters();
              },
              icon: const Icon(Icons.filter_alt_off),
              label: Text('logPost.filter.clearAll'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
