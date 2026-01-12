import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/constants/cooking_time_range.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Section for selecting servings count and cooking time range.
class ServingsCookingTimeSection extends StatelessWidget {
  final int servings;
  final String cookingTimeRange;
  final ValueChanged<int> onServingsChanged;
  final ValueChanged<String> onCookingTimeChanged;

  const ServingsCookingTimeSection({
    super.key,
    required this.servings,
    required this.cookingTimeRange,
    required this.onServingsChanged,
    required this.onCookingTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Servings selector
        Row(
          children: [
            Icon(Icons.people_outline, color: AppColors.primary, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'recipe.servings.label'.tr(),
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _buildServingsSelector(),
        SizedBox(height: 24.h),

        // Cooking time selector
        Row(
          children: [
            Icon(Icons.timer_outlined, color: AppColors.primary, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'recipe.cookingTime.label'.tr(),
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _buildCookingTimeSelector(),
      ],
    );
  }

  Widget _buildServingsSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        // Orange background to show it's editable
        color: AppColors.editableBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.editableBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'recipe.servings.count'.tr(namedArgs: {'count': servings.toString()}),
            style: TextStyle(fontSize: 15.sp),
          ),
          Row(
            children: [
              _buildServingsButton(
                icon: Icons.remove,
                onTap: servings > 1 ? () => onServingsChanged(servings - 1) : null,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  servings.toString(),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildServingsButton(
                icon: Icons.add,
                onTap: servings < 12 ? () => onServingsChanged(servings + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServingsButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.primary : Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isEnabled ? Colors.white : Colors.grey[500],
          size: 18.sp,
        ),
      ),
    );
  }

  Widget _buildCookingTimeSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        // Orange background to show it's editable
        color: AppColors.editableBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.editableBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: cookingTimeRange,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          style: TextStyle(fontSize: 15.sp, color: Colors.black),
          items: CookingTimeRange.values.map((range) {
            return DropdownMenuItem<String>(
              value: range.code,
              child: Text(range.translationKey.tr()),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onCookingTimeChanged(value);
            }
          },
        ),
      ),
    );
  }
}
