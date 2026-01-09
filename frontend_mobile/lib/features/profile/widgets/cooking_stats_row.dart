import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Compact row showing cooking streak and success rate
class CookingStatsRow extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final double successRate;
  final int successCount;
  final int totalLogs;

  const CookingStatsRow({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.successRate,
    required this.successCount,
    required this.totalLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Streak stat
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
            value: currentStreak.toString(),
            label: 'profile.dayStreak'.tr(),
            subtitle: longestStreak > currentStreak
                ? 'profile.best'.tr(namedArgs: {'count': longestStreak.toString()})
                : null,
          ),
        ),
        const SizedBox(width: 12),
        // Success rate stat
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events,
            iconColor: Colors.amber[700]!,
            value: '${(successRate * 100).round()}%',
            label: 'profile.successRate'.tr(),
            subtitle: '$successCount / $totalLogs',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String? subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
