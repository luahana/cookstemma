import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/ingredient.dart';
import '../../providers/cooking_mode_provider.dart';

/// Bottom sheet for ingredients checklist in cooking mode
class CookingIngredientsSheet extends ConsumerWidget {
  final List<Ingredient> ingredients;
  final ScrollController scrollController;
  final DraggableScrollableController sheetController;

  const CookingIngredientsSheet({
    super.key,
    required this.ingredients,
    required this.scrollController,
    required this.sheetController,
  });

  void _toggleSheet() {
    final currentSize = sheetController.size;
    final targetSize = currentSize > 0.15 ? 0.12 : 0.4;
    sheetController.animateTo(
      targetSize,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onDragUpdate(DragUpdateDetails details, BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final delta = -details.delta.dy / screenHeight;
    final newSize = (sheetController.size + delta).clamp(0.12, 0.6);
    sheetController.jumpTo(newSize);
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    double targetSize;

    if (velocity < -500) {
      targetSize = 0.6;
    } else if (velocity > 500) {
      targetSize = 0.12;
    } else {
      final snapSizes = [0.12, 0.4, 0.6];
      targetSize = snapSizes.reduce((a, b) =>
          (a - sheetController.size).abs() < (b - sheetController.size).abs()
              ? a
              : b);
    }

    sheetController.animateTo(
      targetSize,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cookingState = ref.watch(cookingModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Swipeable header area
          GestureDetector(
            onTap: _toggleSheet,
            onVerticalDragUpdate: (details) => _onDragUpdate(details, context),
            onVerticalDragEnd: _onDragEnd,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: 12.h),
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_basket_outlined,
                        size: 24.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'cooking.ingredients'.tr(),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      _buildProgressBadge(cookingState),
                    ],
                  ),
                ),

                Divider(height: 1.h, color: Colors.grey[200]),
              ],
            ),
          ),

          // Ingredients list
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: ingredients.length,
              itemBuilder: (context, index) {
                return _buildIngredientItem(
                  context,
                  ref,
                  index,
                  ingredients[index],
                  cookingState.isIngredientChecked(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBadge(CookingModeState state) {
    final checked = state.checkedIngredientIndices.length;
    final total = ingredients.length;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: checked == total ? AppColors.growth.withValues(alpha: 0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        '$checked / $total',
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: checked == total ? AppColors.growth : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildIngredientItem(
    BuildContext context,
    WidgetRef ref,
    int index,
    Ingredient ingredient,
    bool isChecked,
  ) {
    final displayAmount = ingredient.displayAmount;

    return InkWell(
      onTap: () {
        ref.read(cookingModeProvider.notifier).toggleIngredient(index);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: isChecked ? AppColors.growth : Colors.transparent,
                border: Border.all(
                  color: isChecked ? AppColors.growth : Colors.grey[400]!,
                  width: 2.w,
                ),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: isChecked
                  ? Icon(
                      Icons.check,
                      size: 16.sp,
                      color: Colors.white,
                    )
                  : null,
            ),

            SizedBox(width: 12.w),

            // Ingredient type badge
            _buildTypeBadge(ingredient.type),

            SizedBox(width: 8.w),

            // Name and amount
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: isChecked ? Colors.grey[500] : Colors.grey[800],
                      decoration:
                          isChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (displayAmount.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      displayAmount,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                        decoration:
                            isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    final (color, icon) = _getTypeInfo(type);

    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Icon(
        icon,
        size: 14.sp,
        color: color,
      ),
    );
  }

  (Color, IconData) _getTypeInfo(String type) {
    switch (type.toUpperCase()) {
      case 'MAIN':
        return (Colors.orange, Icons.set_meal_outlined);
      case 'SECONDARY':
        return (Colors.blue, Icons.bakery_dining_outlined);
      case 'SEASONING':
        return (Colors.purple, Icons.opacity_outlined);
      default:
        return (Colors.grey, Icons.circle_outlined);
    }
  }
}
