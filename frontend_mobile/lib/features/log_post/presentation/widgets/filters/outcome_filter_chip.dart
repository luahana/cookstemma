import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Outcome filter chip with emoji and color
class OutcomeFilterChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final Color? color;
  final Color? backgroundColor;
  final bool isSelected;
  final VoidCallback onTap;

  const OutcomeFilterChip({
    super.key,
    required this.label,
    this.emoji,
    this.color,
    this.backgroundColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final effectiveBgColor = backgroundColor ?? AppColors.primary.withValues(alpha: 0.1);

    return Semantics(
      button: true,
      label: '$label filter',
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? effectiveColor : effectiveBgColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected ? effectiveColor : effectiveColor.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: effectiveColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2.h),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: TextStyle(fontSize: 14.sp)),
                SizedBox(width: 6.w),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : effectiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
