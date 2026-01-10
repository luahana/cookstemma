import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/ingredient.dart';

/// Kitchen-Proof Ingredients Section
/// Collapsible ingredient groups with checkboxes and diff badges
class KitchenProofIngredients extends StatefulWidget {
  final List<Ingredient> ingredients;
  final Map<String, dynamic>? changeDiff;
  final bool showDiffBadges;

  const KitchenProofIngredients({
    super.key,
    required this.ingredients,
    this.changeDiff,
    this.showDiffBadges = false,
  });

  @override
  State<KitchenProofIngredients> createState() => _KitchenProofIngredientsState();
}

class _KitchenProofIngredientsState extends State<KitchenProofIngredients> {
  final Set<String> _checkedIngredients = {};
  bool _showDiff = true;

  List<Ingredient> get mainIngredients =>
      widget.ingredients.where((i) => i.type == 'MAIN').toList();

  List<Ingredient> get secondaryIngredients =>
      widget.ingredients.where((i) => i.type == 'SECONDARY').toList();

  List<Ingredient> get seasoningIngredients =>
      widget.ingredients.where((i) => i.type == 'SEASONING').toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with diff toggle
        _buildHeader(),
        const SizedBox(height: 12),
        // Ingredient groups
        if (mainIngredients.isNotEmpty)
          _IngredientGroupCard(
            title: 'recipe.ingredients.main'.tr(),
            icon: Icons.restaurant,
            ingredients: mainIngredients,
            checkedIngredients: _checkedIngredients,
            onToggle: _toggleIngredient,
            changeDiff: widget.changeDiff,
            showDiff: widget.showDiffBadges && _showDiff,
          ),
        if (secondaryIngredients.isNotEmpty) ...[
          const SizedBox(height: 12),
          _IngredientGroupCard(
            title: 'recipe.ingredients.secondary'.tr(),
            icon: Icons.eco,
            ingredients: secondaryIngredients,
            checkedIngredients: _checkedIngredients,
            onToggle: _toggleIngredient,
            changeDiff: widget.changeDiff,
            showDiff: widget.showDiffBadges && _showDiff,
          ),
        ],
        if (seasoningIngredients.isNotEmpty) ...[
          const SizedBox(height: 12),
          _IngredientGroupCard(
            title: 'recipe.ingredients.seasoning'.tr(),
            icon: Icons.local_fire_department,
            ingredients: seasoningIngredients,
            checkedIngredients: _checkedIngredients,
            onToggle: _toggleIngredient,
            changeDiff: widget.changeDiff,
            showDiff: widget.showDiffBadges && _showDiff,
          ),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.shopping_basket_outlined, size: 20),
        const SizedBox(width: 8),
        Text(
          'recipe.ingredients.title'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (widget.showDiffBadges)
          TextButton.icon(
            onPressed: () => setState(() => _showDiff = !_showDiff),
            icon: Icon(
              _showDiff ? Icons.visibility : Icons.visibility_off,
              size: 16,
            ),
            label: Text(
              _showDiff ? 'recipe.diff.hide'.tr() : 'recipe.diff.show'.tr(),
              style: const TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }

  void _toggleIngredient(String ingredientKey) {
    setState(() {
      if (_checkedIngredients.contains(ingredientKey)) {
        _checkedIngredients.remove(ingredientKey);
      } else {
        _checkedIngredients.add(ingredientKey);
      }
    });
  }
}

/// Collapsible card for ingredient group
class _IngredientGroupCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Ingredient> ingredients;
  final Set<String> checkedIngredients;
  final Function(String) onToggle;
  final Map<String, dynamic>? changeDiff;
  final bool showDiff;

  const _IngredientGroupCard({
    required this.title,
    required this.icon,
    required this.ingredients,
    required this.checkedIngredients,
    required this.onToggle,
    this.changeDiff,
    this.showDiff = false,
  });

  @override
  State<_IngredientGroupCard> createState() => _IngredientGroupCardState();
}

class _IngredientGroupCardState extends State<_IngredientGroupCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header - tappable to expand/collapse
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(widget.icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.badgeBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.ingredients.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // Content - animated expand/collapse
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildIngredientsList(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsList() {
    return Column(
      children: [
        const Divider(height: 1),
        ...widget.ingredients.asMap().entries.map((entry) {
          final index = entry.key;
          final ingredient = entry.value;
          final ingredientKey = '${ingredient.name}_${ingredient.amount}';
          final isChecked = widget.checkedIngredients.contains(ingredientKey);
          final diffStatus = _getDiffStatus(ingredient);

          return Column(
            children: [
              _IngredientRow(
                ingredient: ingredient,
                isChecked: isChecked,
                onToggle: () => widget.onToggle(ingredientKey),
                diffStatus: widget.showDiff ? diffStatus : null,
              ),
              if (index < widget.ingredients.length - 1)
                const Divider(height: 1, indent: 48),
            ],
          );
        }),
      ],
    );
  }

  IngredientDiffStatus? _getDiffStatus(Ingredient ingredient) {
    if (widget.changeDiff == null) return null;

    final ingredientsDiff = widget.changeDiff!['ingredients'] as Map<String, dynamic>?;
    if (ingredientsDiff == null) return null;

    // Check added
    final added = ingredientsDiff['added'] as List<dynamic>?;
    if (added != null) {
      for (final item in added) {
        if (item.toString().contains(ingredient.name)) {
          return IngredientDiffStatus.added;
        }
      }
    }

    // Check removed
    final removed = ingredientsDiff['removed'] as List<dynamic>?;
    if (removed != null) {
      for (final item in removed) {
        if (item.toString().contains(ingredient.name)) {
          return IngredientDiffStatus.removed;
        }
      }
    }

    // Check modified
    final modified = ingredientsDiff['modified'] as List<dynamic>?;
    if (modified != null) {
      for (final item in modified) {
        if (item is Map && item['to']?.toString().contains(ingredient.name) == true) {
          return IngredientDiffStatus(
            type: DiffType.modified,
            fromValue: item['from']?.toString(),
            toValue: item['to']?.toString(),
          );
        }
      }
    }

    return null;
  }
}

/// Single ingredient row with checkbox and diff badge
class _IngredientRow extends StatelessWidget {
  final Ingredient ingredient;
  final bool isChecked;
  final VoidCallback onToggle;
  final IngredientDiffStatus? diffStatus;

  const _IngredientRow({
    required this.ingredient,
    required this.isChecked,
    required this.onToggle,
    this.diffStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isRemoved = diffStatus?.type == DiffType.removed;

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isChecked,
                onChanged: (_) => onToggle(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 12),
            // Ingredient name
            Expanded(
              child: Text(
                ingredient.name,
                style: TextStyle(
                  fontSize: 14,
                  decoration: isRemoved ? TextDecoration.lineThrough : null,
                  color: isRemoved ? AppColors.diffRemoved : AppColors.textPrimary,
                ),
              ),
            ),
            // Amount
            if (ingredient.amount != null && ingredient.amount!.isNotEmpty)
              Text(
                ingredient.amount!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  decoration: isRemoved ? TextDecoration.lineThrough : null,
                ),
              ),
            // Diff badge
            if (diffStatus != null) ...[
              const SizedBox(width: 8),
              _DiffBadge(status: diffStatus!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Diff badge showing change type
class _DiffBadge extends StatelessWidget {
  final IngredientDiffStatus status;

  const _DiffBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, text) = switch (status.type) {
      DiffType.added => (AppColors.diffAdded, AppColors.diffAddedBg, '+'),
      DiffType.removed => (AppColors.diffRemoved, AppColors.diffRemovedBg, '-'),
      DiffType.modified => (AppColors.diffModified, AppColors.diffModifiedBg, '~'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// Diff type enum
enum DiffType { added, removed, modified }

/// Diff status for an ingredient
class IngredientDiffStatus {
  final DiffType type;
  final String? fromValue;
  final String? toValue;

  const IngredientDiffStatus({
    required this.type,
    this.fromValue,
    this.toValue,
  });

  static const added = IngredientDiffStatus(type: DiffType.added);
  static const removed = IngredientDiffStatus(type: DiffType.removed);
}
