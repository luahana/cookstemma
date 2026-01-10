import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// GitHub-style diff section showing what changed from parent recipe
class ChangeDiffSection extends StatefulWidget {
  final Map<String, dynamic> changeDiff;
  final List<String>? changeCategories;
  final String? changeReason;

  const ChangeDiffSection({
    super.key,
    required this.changeDiff,
    this.changeCategories,
    this.changeReason,
  });

  @override
  State<ChangeDiffSection> createState() => _ChangeDiffSectionState();
}

class _ChangeDiffSectionState extends State<ChangeDiffSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final ingredientsDiff = widget.changeDiff['ingredients'] as Map<String, dynamic>?;
    final stepsDiff = widget.changeDiff['steps'] as Map<String, dynamic>?;

    final hasIngredientChanges = ingredientsDiff != null && _hasChanges(ingredientsDiff);
    final hasStepChanges = stepsDiff != null && _hasChanges(stepsDiff);

    if (!hasIngredientChanges && !hasStepChanges) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Row(
                children: [
                  Icon(Icons.compare_arrows, size: 20.sp, color: AppColors.diffModified),
                  SizedBox(width: 8.w),
                  Text(
                    'recipe.diff.whatChanged'.tr(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Change category chips
                  if (widget.changeCategories != null && widget.changeCategories!.isNotEmpty)
                    ...widget.changeCategories!.take(2).map((cat) => Padding(
                      padding: EdgeInsets.only(right: 4.w),
                      child: _ChangeCategoryChip(category: cat),
                    )),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // Change reason (if provided)
          if (widget.changeReason != null && widget.changeReason!.isNotEmpty && _isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote, size: 16.sp, color: AppColors.textSecondary),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      widget.changeReason!,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1),
                if (ingredientsDiff != null && hasIngredientChanges)
                  _DiffGroup(
                    title: 'recipe.diff.ingredients'.tr(),
                    icon: Icons.restaurant,
                    diffData: ingredientsDiff,
                  ),
                if (stepsDiff != null && hasStepChanges) ...[
                  if (hasIngredientChanges) const Divider(height: 1),
                  _DiffGroup(
                    title: 'recipe.diff.steps'.tr(),
                    icon: Icons.format_list_numbered,
                    diffData: stepsDiff,
                  ),
                ],
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  bool _hasChanges(Map<String, dynamic> diff) {
    final added = diff['added'] as List<dynamic>?;
    final removed = diff['removed'] as List<dynamic>?;
    final modified = diff['modified'] as List<dynamic>?;
    return (added?.isNotEmpty ?? false) ||
        (removed?.isNotEmpty ?? false) ||
        (modified?.isNotEmpty ?? false);
  }
}

/// Change category chip
class _ChangeCategoryChip extends StatelessWidget {
  final String category;

  const _ChangeCategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (category.toUpperCase()) {
      'INGREDIENT' => (AppColors.diffAdded, 'recipe.category.ingredient'.tr()),
      'TECHNIQUE' => (AppColors.primary, 'recipe.category.technique'.tr()),
      'AMOUNT' => (AppColors.diffModified, 'recipe.category.amount'.tr()),
      'SEASONING' => (AppColors.rating, 'recipe.category.seasoning'.tr()),
      _ => (AppColors.textSecondary, category),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '+$label',
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

/// Group of diff items (added/removed/modified)
class _DiffGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final Map<String, dynamic> diffData;

  const _DiffGroup({
    required this.title,
    required this.icon,
    required this.diffData,
  });

  @override
  Widget build(BuildContext context) {
    final added = (diffData['added'] as List<dynamic>?)?.cast<String>() ?? [];
    final removed = (diffData['removed'] as List<dynamic>?)?.cast<String>() ?? [];
    final modified = (diffData['modified'] as List<dynamic>?) ?? [];

    return Padding(
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group title
          Row(
            children: [
              Icon(icon, size: 16.sp, color: AppColors.textSecondary),
              SizedBox(width: 6.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // Added items
          if (added.isNotEmpty)
            _DiffItemList(
              type: _DiffType.added,
              items: added,
            ),
          // Modified items
          if (modified.isNotEmpty)
            _DiffModifiedList(items: modified),
          // Removed items
          if (removed.isNotEmpty)
            _DiffItemList(
              type: _DiffType.removed,
              items: removed,
            ),
        ],
      ),
    );
  }
}

enum _DiffType { added, removed }

/// List of added or removed items
class _DiffItemList extends StatelessWidget {
  final _DiffType type;
  final List<String> items;

  const _DiffItemList({
    required this.type,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, prefix) = switch (type) {
      _DiffType.added => (AppColors.diffAdded, AppColors.diffAddedBg, '+'),
      _DiffType.removed => (AppColors.diffRemoved, AppColors.diffRemovedBg, '-'),
    };

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prefix,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: color,
                    decoration: type == _DiffType.removed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

/// List of modified items (from -> to)
class _DiffModifiedList extends StatelessWidget {
  final List<dynamic> items;

  const _DiffModifiedList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.diffModifiedBg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          final from = item is Map ? item['from']?.toString() ?? '' : '';
          final to = item is Map ? item['to']?.toString() ?? '' : item.toString();

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '~',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.diffModified,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13.sp, color: AppColors.diffModified),
                      children: [
                        if (from.isNotEmpty) ...[
                          TextSpan(
                            text: from,
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const TextSpan(text: '  '),
                          const TextSpan(text: '→  '),
                        ],
                        TextSpan(
                          text: to,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
