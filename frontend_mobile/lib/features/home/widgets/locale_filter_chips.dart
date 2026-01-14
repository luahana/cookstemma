import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Popular cooking style options for filtering
class _FilterStyleOption {
  final String countryCode;
  final String labelKey;

  const _FilterStyleOption(this.countryCode, this.labelKey);

  String get flagEmoji {
    if (countryCode == 'international') return '🌍';
    try {
      return CountryParser.parseCountryCode(countryCode).flagEmoji;
    } catch (_) {
      return '🌍';
    }
  }
}

/// Popular filter options
const _filterOptions = [
  _FilterStyleOption('KR', 'locale.korean'),
  _FilterStyleOption('US', 'locale.american'),
  _FilterStyleOption('JP', 'locale.japanese'),
  _FilterStyleOption('CN', 'locale.chinese'),
  _FilterStyleOption('IT', 'locale.italian'),
  _FilterStyleOption('MX', 'locale.mexican'),
  _FilterStyleOption('TH', 'locale.thai'),
  _FilterStyleOption('IN', 'locale.indian'),
  _FilterStyleOption('FR', 'locale.french'),
  _FilterStyleOption('international', 'locale.international'),
];

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
          ..._filterOptions.map((option) => Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: _buildChip(
                  label: '${option.flagEmoji} ${option.labelKey.tr()}',
                  isSelected: selectedLocale == option.countryCode,
                  onTap: () => onLocaleChanged(option.countryCode),
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
