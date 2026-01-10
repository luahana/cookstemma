import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/locale_dropdown.dart';

/// Horizontal scrollable chips for browsing by cooking style/cuisine.
class CookingStyleChips extends StatelessWidget {
  final ValueChanged<String> onStyleSelected;

  const CookingStyleChips({
    super.key,
    required this.onStyleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'search.browseByCuisine'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        // Chips
        SizedBox(
          height: 44.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: CulinaryLocale.options.length,
            separatorBuilder: (context, index) => SizedBox(width: 10.w),
            itemBuilder: (context, index) {
              final locale = CulinaryLocale.options[index];
              return _CuisineStyleChip(
                emoji: locale.flagEmoji,
                label: locale.labelKey.tr(),
                onTap: () => onStyleSelected(locale.labelKey.tr()),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CuisineStyleChip extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _CuisineStyleChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: 18.sp)),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
