import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Reusable filter chip widget for filter bars throughout the app.
/// Supports optional leading widget (emoji, icon) and customizable colors.
class AppFilterChip extends StatelessWidget {
  final String label;
  final Widget? leading;
  final Color? color;
  final Color? backgroundColor;
  final bool isSelected;
  final VoidCallback onTap;

  const AppFilterChip({
    super.key,
    required this.label,
    this.leading,
    this.color,
    this.backgroundColor,
    required this.isSelected,
    required this.onTap,
  });

  /// Create a filter chip with an emoji
  factory AppFilterChip.emoji({
    Key? key,
    required String label,
    required String emoji,
    Color? color,
    Color? backgroundColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AppFilterChip(
      key: key,
      label: label,
      leading: Text(emoji, style: TextStyle(fontSize: 14.sp)),
      color: color,
      backgroundColor: backgroundColor,
      isSelected: isSelected,
      onTap: onTap,
    );
  }

  /// Create a filter chip with an icon
  factory AppFilterChip.icon({
    Key? key,
    required String label,
    required IconData icon,
    Color? color,
    Color? backgroundColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AppFilterChip(
      key: key,
      label: label,
      leading: Icon(icon, size: 16.sp),
      color: color,
      backgroundColor: backgroundColor,
      isSelected: isSelected,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final effectiveBgColor =
        backgroundColor ?? AppColors.primary.withValues(alpha: 0.1);

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
              color: isSelected
                  ? effectiveColor
                  : effectiveColor.withValues(alpha: 0.3),
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
              if (leading != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: isSelected ? Colors.white : effectiveColor,
                  ),
                  child: leading!,
                ),
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
