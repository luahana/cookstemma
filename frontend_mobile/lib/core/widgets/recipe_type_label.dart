import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/constants/app_icons.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Displays recipe type icon with food name label.
/// Shows different icons for original vs variant recipes.
class RecipeTypeLabel extends StatelessWidget {
  final String foodName;
  final bool isVariant;
  final double? fontSize;
  final double? iconSize;
  final Color? color;
  final FontWeight? fontWeight;

  const RecipeTypeLabel({
    super.key,
    required this.foodName,
    required this.isVariant,
    this.fontSize,
    this.iconSize,
    this.color,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final effectiveFontSize = fontSize ?? 12.sp;
    final effectiveIconSize = iconSize ?? effectiveFontSize;
    final effectiveFontWeight = fontWeight ?? FontWeight.bold;

    return Row(
      children: [
        Icon(
          isVariant ? AppIcons.variantCreate : AppIcons.originalRecipe,
          size: effectiveIconSize,
          color: effectiveColor,
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(
            foodName,
            style: TextStyle(
              fontSize: effectiveFontSize,
              fontWeight: effectiveFontWeight,
              color: effectiveColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
