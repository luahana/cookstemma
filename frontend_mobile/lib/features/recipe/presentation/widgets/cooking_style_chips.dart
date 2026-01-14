import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Popular cooking style options for browsing
class _CookingStyleOption {
  final String countryCode;
  final String labelKey;

  const _CookingStyleOption(this.countryCode, this.labelKey);

  String get flagEmoji {
    if (countryCode == 'international') return '🌍';
    try {
      return CountryParser.parseCountryCode(countryCode).flagEmoji;
    } catch (_) {
      return '🌍';
    }
  }
}

/// Popular cooking styles for discovery
const _popularStyles = [
  _CookingStyleOption('KR', 'locale.korean'),
  _CookingStyleOption('US', 'locale.american'),
  _CookingStyleOption('JP', 'locale.japanese'),
  _CookingStyleOption('CN', 'locale.chinese'),
  _CookingStyleOption('IT', 'locale.italian'),
  _CookingStyleOption('MX', 'locale.mexican'),
  _CookingStyleOption('TH', 'locale.thai'),
  _CookingStyleOption('IN', 'locale.indian'),
  _CookingStyleOption('FR', 'locale.french'),
  _CookingStyleOption('international', 'locale.international'),
];

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
            itemCount: _popularStyles.length,
            separatorBuilder: (context, index) => SizedBox(width: 10.w),
            itemBuilder: (context, index) {
              final style = _popularStyles[index];
              return _CuisineStyleChip(
                emoji: style.flagEmoji,
                label: style.labelKey.tr(),
                onTap: () => onStyleSelected(style.labelKey.tr()),
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
