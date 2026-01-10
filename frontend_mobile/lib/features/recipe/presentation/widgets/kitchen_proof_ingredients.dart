import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/providers/measurement_preference_provider.dart';
import 'package:pairing_planet2_frontend/core/services/measurement_service.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/ingredient_dto.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/ingredient.dart';

/// Kitchen-Proof Ingredients Section
/// Collapsible ingredient groups with checkboxes and diff badges
class KitchenProofIngredients extends ConsumerStatefulWidget {
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
  ConsumerState<KitchenProofIngredients> createState() => _KitchenProofIngredientsState();
}

class _KitchenProofIngredientsState extends ConsumerState<KitchenProofIngredients> {
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
    // Watch measurement preference for auto-conversion
    final measurementPref = ref.watch(measurementPreferenceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with diff toggle
        _buildHeader(),
        SizedBox(height: 12.h),
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
            measurementPreference: measurementPref,
          ),
        if (secondaryIngredients.isNotEmpty) ...[
          SizedBox(height: 12.h),
          _IngredientGroupCard(
            title: 'recipe.ingredients.secondary'.tr(),
            icon: Icons.eco,
            ingredients: secondaryIngredients,
            checkedIngredients: _checkedIngredients,
            onToggle: _toggleIngredient,
            changeDiff: widget.changeDiff,
            showDiff: widget.showDiffBadges && _showDiff,
            measurementPreference: measurementPref,
          ),
        ],
        if (seasoningIngredients.isNotEmpty) ...[
          SizedBox(height: 12.h),
          _IngredientGroupCard(
            title: 'recipe.ingredients.seasoning'.tr(),
            icon: Icons.local_fire_department,
            ingredients: seasoningIngredients,
            checkedIngredients: _checkedIngredients,
            onToggle: _toggleIngredient,
            changeDiff: widget.changeDiff,
            showDiff: widget.showDiffBadges && _showDiff,
            measurementPreference: measurementPref,
          ),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.shopping_basket_outlined, size: 20.sp),
        SizedBox(width: 8.w),
        Text(
          'recipe.ingredients.title'.tr(),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (widget.showDiffBadges)
          TextButton.icon(
            onPressed: () => setState(() => _showDiff = !_showDiff),
            icon: Icon(
              _showDiff ? Icons.visibility : Icons.visibility_off,
              size: 16.sp,
            ),
            label: Text(
              _showDiff ? 'recipe.diff.hide'.tr() : 'recipe.diff.show'.tr(),
              style: TextStyle(fontSize: 12.sp),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
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
  final MeasurementPreference measurementPreference;

  const _IngredientGroupCard({
    required this.title,
    required this.icon,
    required this.ingredients,
    required this.checkedIngredients,
    required this.onToggle,
    this.changeDiff,
    this.showDiff = false,
    required this.measurementPreference,
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
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header - tappable to expand/collapse
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Row(
                children: [
                  Icon(widget.icon, size: 18.sp, color: AppColors.primary),
                  SizedBox(width: 8.w),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.badgeBackground,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '${widget.ingredients.length}',
                      style: TextStyle(
                        fontSize: 12.sp,
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
          final ingredientKey = '${ingredient.name}_${ingredient.displayAmount}';
          final isChecked = widget.checkedIngredients.contains(ingredientKey);
          final diffStatus = _getDiffStatus(ingredient);

          return Column(
            children: [
              _IngredientRow(
                ingredient: ingredient,
                isChecked: isChecked,
                onToggle: () => widget.onToggle(ingredientKey),
                diffStatus: widget.showDiff ? diffStatus : null,
                measurementPreference: widget.measurementPreference,
              ),
              if (index < widget.ingredients.length - 1)
                Divider(height: 1, indent: 48.w),
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
  final MeasurementPreference measurementPreference;

  const _IngredientRow({
    required this.ingredient,
    required this.isChecked,
    required this.onToggle,
    this.diffStatus,
    required this.measurementPreference,
  });

  /// Get the display amount, converted based on user preference
  String _getConvertedAmount() {
    // If ingredient has structured measurements, convert based on preference
    if (ingredient.hasStructuredMeasurement) {
      final unitEnum = MeasurementUnit.values.firstWhere(
        (u) => u.name == ingredient.unit,
        orElse: () => MeasurementUnit.piece,
      );
      final result = MeasurementService.convertForPreference(
        ingredient.quantity,
        unitEnum,
        measurementPreference,
      );
      return result.format();
    }
    // Legacy: use original amount string
    return ingredient.amount ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isRemoved = diffStatus?.type == DiffType.removed;
    final displayAmount = _getConvertedAmount();

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: Checkbox(
                value: isChecked,
                onChanged: (_) => onToggle(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.r),
                ),
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            SizedBox(width: 12.w),
            // Ingredient name
            Expanded(
              child: Text(
                ingredient.name,
                style: TextStyle(
                  fontSize: 14.sp,
                  decoration: isRemoved ? TextDecoration.lineThrough : null,
                  color: isRemoved ? AppColors.diffRemoved : AppColors.textPrimary,
                ),
              ),
            ),
            // Amount - converted based on user preference
            if (displayAmount.isNotEmpty)
              Text(
                displayAmount,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  decoration: isRemoved ? TextDecoration.lineThrough : null,
                ),
              ),
            // Diff badge
            if (diffStatus != null) ...[
              SizedBox(width: 8.w),
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
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
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
