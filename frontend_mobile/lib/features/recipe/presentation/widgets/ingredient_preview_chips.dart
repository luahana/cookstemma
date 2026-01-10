import 'package:flutter/material.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Ingredient preview data for browse cards
class IngredientPreview {
  final String name;
  final String type; // MAIN, SECONDARY, SEASONING
  final DiffType? diffType; // added, removed, modified, null

  IngredientPreview({
    required this.name,
    required this.type,
    this.diffType,
  });
}

enum DiffType { added, removed, modified }

/// Compact ingredient preview for recipe cards
/// Shows ingredients grouped by MAIN/SECONDARY/SEASONING with optional diff badges
class IngredientPreviewChips extends StatelessWidget {
  final List<IngredientPreview> ingredients;
  final bool showDiffBadges;
  final int maxItemsPerCategory;

  const IngredientPreviewChips({
    super.key,
    required this.ingredients,
    this.showDiffBadges = false,
    this.maxItemsPerCategory = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (ingredients.isEmpty) {
      return const SizedBox.shrink();
    }

    final mainIngredients =
        ingredients.where((i) => i.type == 'MAIN').take(maxItemsPerCategory).toList();
    final secondaryIngredients =
        ingredients.where((i) => i.type == 'SECONDARY').take(maxItemsPerCategory).toList();
    final seasoningIngredients =
        ingredients.where((i) => i.type == 'SEASONING').take(maxItemsPerCategory).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mainIngredients.isNotEmpty)
            _buildCategoryRow(
              icon: '🥩',
              label: 'Main',
              items: mainIngredients,
            ),
          if (secondaryIngredients.isNotEmpty) ...[
            if (mainIngredients.isNotEmpty) const SizedBox(height: 6),
            _buildCategoryRow(
              icon: '🥬',
              label: 'Side',
              items: secondaryIngredients,
            ),
          ],
          if (seasoningIngredients.isNotEmpty) ...[
            if (mainIngredients.isNotEmpty || secondaryIngredients.isNotEmpty)
              const SizedBox(height: 6),
            _buildCategoryRow(
              icon: '🌶️',
              label: 'Season',
              items: seasoningIngredients,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryRow({
    required String icon,
    required String label,
    required List<IngredientPreview> items,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: items.map((item) => _buildIngredientChip(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientChip(IngredientPreview item) {
    if (showDiffBadges && item.diffType != null) {
      return _buildDiffChip(item);
    }

    return Text(
      item.name,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildDiffChip(IngredientPreview item) {
    Color bgColor;
    Color textColor;
    String prefix;

    switch (item.diffType!) {
      case DiffType.added:
        bgColor = AppColors.diffAddedBg;
        textColor = AppColors.diffAdded;
        prefix = '+';
        break;
      case DiffType.removed:
        bgColor = AppColors.diffRemovedBg;
        textColor = AppColors.diffRemoved;
        prefix = '-';
        break;
      case DiffType.modified:
        bgColor = AppColors.diffModifiedBg;
        textColor = AppColors.diffModified;
        prefix = '~';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$prefix${item.name}',
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
