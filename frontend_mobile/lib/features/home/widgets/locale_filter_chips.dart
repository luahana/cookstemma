import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/locale_dropdown.dart';

/// Horizontal scrollable filter chips for culinary locale selection
class LocaleFilterChips extends StatelessWidget {
  final String? selectedLocale;
  final ValueChanged<String?> onLocaleChanged;

  const LocaleFilterChips({
    super.key,
    this.selectedLocale,
    required this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          // "All" chip
          _buildChip(
            label: 'locale.all'.tr(),
            isSelected: selectedLocale == null,
            onTap: () => onLocaleChanged(null),
          ),
          SizedBox(width: 8.w),
          // Locale chips
          ...CulinaryLocale.options.map((locale) => Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: _buildChip(
                  label: '${locale.flagEmoji} ${locale.labelKey.tr()}',
                  isSelected: selectedLocale == locale.code,
                  onTap: () => onLocaleChanged(locale.code),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
