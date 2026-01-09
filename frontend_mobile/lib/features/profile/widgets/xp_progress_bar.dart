import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// XP Progress Bar with level indicator
class XpProgressBar extends StatelessWidget {
  final int level;
  final String levelName;
  final int totalXp;
  final int xpForCurrentLevel;
  final int xpForNextLevel;
  final double levelProgress;

  const XpProgressBar({
    super.key,
    required this.level,
    required this.levelName,
    required this.totalXp,
    required this.xpForCurrentLevel,
    required this.xpForNextLevel,
    required this.levelProgress,
  });

  Color get _progressColor {
    if (level <= 5) return const Color(0xFF78909C); // Beginner - Grey
    if (level <= 10) return const Color(0xFF4CAF50); // Home Cook - Green
    if (level <= 15) return const Color(0xFF2196F3); // Skilled Cook - Blue
    if (level <= 20) return const Color(0xFF9C27B0); // Home Chef - Purple
    if (level <= 25) return const Color(0xFFFF9800); // Expert Chef - Orange
    return const Color(0xFFFFD700); // Master Chef - Gold
  }

  Color get _progressBackgroundColor => _progressColor.withValues(alpha: 0.2);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _progressColor.withValues(alpha: 0.1),
            _progressColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _progressColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with DNA label and level badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: _progressColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'profile.cookingDna'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _progressColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Lv.$level',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: levelProgress,
              minHeight: 10,
              backgroundColor: _progressBackgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
            ),
          ),
          const SizedBox(height: 8),
          // Level name and XP progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'profile.$levelName'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _progressColor,
                ),
              ),
              Text(
                '$totalXp / $xpForNextLevel XP',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
