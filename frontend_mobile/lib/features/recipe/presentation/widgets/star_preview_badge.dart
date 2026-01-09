import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Badge showing star metrics: variant count and log count
/// Used on original/root recipe cards to show the "star" (recipe family) size
class StarPreviewBadge extends StatelessWidget {
  final int variantCount;
  final int logCount;
  final bool compact;

  const StarPreviewBadge({
    super.key,
    required this.variantCount,
    required this.logCount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show if no activity
    if (variantCount == 0 && logCount == 0) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return _buildCompact();
    }

    return _buildFull();
  }

  Widget _buildFull() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '⭐',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 6),
          Text(
            'recipe.starLabel'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (variantCount > 0) ...[
            const SizedBox(width: 8),
            const Text(
              '🔀',
              style: TextStyle(fontSize: 10),
            ),
            const SizedBox(width: 2),
            Text(
              variantCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (logCount > 0) ...[
            const SizedBox(width: 8),
            const Text(
              '📝',
              style: TextStyle(fontSize: 10),
            ),
            const SizedBox(width: 2),
            Text(
              logCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompact() {
    final parts = <String>[];
    if (variantCount > 0) {
      parts.add('🔀$variantCount');
    }
    if (logCount > 0) {
      parts.add('📝$logCount');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        parts.join(' · '),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Badge showing "Based on: [Root Recipe Title]" for variant recipes
class BasedOnBadge extends StatelessWidget {
  final String rootTitle;
  final VoidCallback? onTap;

  const BasedOnBadge({
    super.key,
    required this.rootTitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '📍',
              style: TextStyle(fontSize: 11),
            ),
            const SizedBox(width: 4),
            Text(
              'recipe.basedOn'.tr(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                rootTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: Colors.white70,
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
