import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Summary of changes for variant recipes
class DiffSummary {
  final int addedCount;
  final int removedCount;
  final int modifiedCount;

  DiffSummary({
    this.addedCount = 0,
    this.removedCount = 0,
    this.modifiedCount = 0,
  });

  bool get hasChanges => addedCount > 0 || removedCount > 0 || modifiedCount > 0;

  /// Parse from backend changeDiff map
  factory DiffSummary.fromChangeDiff(Map<String, dynamic>? changeDiff) {
    if (changeDiff == null) return DiffSummary();

    int added = 0;
    int removed = 0;
    int modified = 0;

    // Parse ingredients section
    final ingredients = changeDiff['ingredients'] as Map<String, dynamic>?;
    if (ingredients != null) {
      added += (ingredients['added'] as List?)?.length ?? 0;
      removed += (ingredients['removed'] as List?)?.length ?? 0;
      modified += (ingredients['modified'] as List?)?.length ?? 0;
    }

    // Parse steps section
    final steps = changeDiff['steps'] as Map<String, dynamic>?;
    if (steps != null) {
      added += (steps['added'] as List?)?.length ?? 0;
      removed += (steps['removed'] as List?)?.length ?? 0;
      modified += (steps['modified'] as List?)?.length ?? 0;
    }

    return DiffSummary(
      addedCount: added,
      removedCount: removed,
      modifiedCount: modified,
    );
  }
}

/// Row showing diff summary: "+2 added · -1 removed · ~1 modified"
class DiffSummaryRow extends StatelessWidget {
  final DiffSummary summary;
  final bool compact;

  const DiffSummaryRow({
    super.key,
    required this.summary,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!summary.hasChanges) {
      return const SizedBox.shrink();
    }

    final parts = <Widget>[];

    if (summary.addedCount > 0) {
      parts.add(_buildChip(
        '+${summary.addedCount}',
        'recipe.diff.added'.tr(),
        AppColors.diffAdded,
        AppColors.diffAddedBg,
      ));
    }

    if (summary.removedCount > 0) {
      if (parts.isNotEmpty) {
        parts.add(_buildDot());
      }
      parts.add(_buildChip(
        '-${summary.removedCount}',
        'recipe.diff.removed'.tr(),
        AppColors.diffRemoved,
        AppColors.diffRemovedBg,
      ));
    }

    if (summary.modifiedCount > 0) {
      if (parts.isNotEmpty) {
        parts.add(_buildDot());
      }
      parts.add(_buildChip(
        '~${summary.modifiedCount}',
        'recipe.diff.modified'.tr(),
        AppColors.diffModified,
        AppColors.diffModifiedBg,
      ));
    }

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: parts,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(
            'recipe.diff.changes'.tr(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          ...parts,
        ],
      ),
    );
  }

  Widget _buildChip(String count, String label, Color textColor, Color bgColor) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          count,
          style: TextStyle(
            fontSize: 11,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            count,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '·',
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
