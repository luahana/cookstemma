import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/theme/app_input_styles.dart';

/// Dropdown widget for selecting food/cooking style (country-based)
/// Displays as "🇰🇷 Style" format
class FoodStyleDropdown extends StatelessWidget {
  final String? value; // ISO country code (e.g., "KR", "US") or "other"
  final String? preferredStyle; // User's preferred cooking style from settings
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const FoodStyleDropdown({
    super.key,
    this.value,
    this.preferredStyle,
    required this.onChanged,
    this.enabled = true,
  });

  /// Get country by ISO code
  Country? _getCountry(String? code) {
    if (code == null || code.isEmpty || code == 'international') return null;
    try {
      return CountryParser.parseCountryCode(code);
    } catch (_) {
      return null;
    }
  }

  /// Normalize legacy locale codes to ISO country codes
  String? _normalizeValue(String? value) {
    if (value == null || value.isEmpty) return null;

    // Map legacy full locale codes to ISO country codes
    final legacyMap = {
      'ko-KR': 'KR',
      'en-US': 'US',
      'ja-JP': 'JP',
      'zh-CN': 'CN',
      'it-IT': 'IT',
      'es-MX': 'MX',
      'th-TH': 'TH',
      'hi-IN': 'IN',
      'fr-FR': 'FR',
    };

    return legacyMap[value] ?? value;
  }

  void _showPicker(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        onChanged(country.countryCode);
      },
      countryListTheme: CountryListThemeData(
        backgroundColor: Colors.white,
        textStyle: TextStyle(fontSize: 16.sp, color: Colors.black87),
        searchTextStyle: TextStyle(fontSize: 16.sp, color: Colors.black87),
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.7,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        inputDecoration: InputDecoration(
          hintText: 'foodStyle.searchHint'.tr(),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedValue = _normalizeValue(value);
    final country = _getCountry(normalizedValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'foodStyle.title'.tr(),
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: enabled ? () => _showPicker(context) : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            decoration: enabled
                ? AppInputStyles.editableBoxDecoration
                : BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
            child: Row(
              children: [
                if (country != null) ...[
                  Text(country.flagEmoji, style: TextStyle(fontSize: 20.sp)),
                  SizedBox(width: 8.w),
                  Text(
                    'foodStyle.style'.tr(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: enabled ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ] else if (normalizedValue == 'international') ...[
                  Text('🌍', style: TextStyle(fontSize: 20.sp)),
                  SizedBox(width: 8.w),
                  Text(
                    'foodStyle.international'.tr(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: enabled ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ] else ...[
                  Text(
                    'foodStyle.select'.tr(),
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                ],
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down,
                  color: enabled ? Colors.grey[700] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8.h),
        // Quick select buttons row
        Row(
          children: [
            // Preferred country button (if set and not "other")
            if (preferredStyle != null &&
                preferredStyle!.isNotEmpty &&
                preferredStyle != 'international') ...[
              _buildPreferredStyleButton(normalizedValue),
              SizedBox(width: 8.w),
            ],
            // "Other/International" option button
            _buildOtherButton(normalizedValue),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          'foodStyle.helperText'.tr(),
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  /// Build preferred country quick-select button
  Widget _buildPreferredStyleButton(String? normalizedValue) {
    final preferredCountry = _getCountry(preferredStyle);
    if (preferredCountry == null) return const SizedBox.shrink();

    final isSelected = normalizedValue == preferredStyle;

    return GestureDetector(
      onTap: enabled ? () => onChanged(preferredStyle) : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.editableBackground : Colors.grey[50],
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.editableBorder : Colors.grey[200]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(preferredCountry.flagEmoji, style: TextStyle(fontSize: 16.sp)),
            SizedBox(width: 6.w),
            Text(
              preferredCountry.name,
              style: TextStyle(
                fontSize: 13.sp,
                color: isSelected ? AppColors.primary : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build "Other/International" quick-select button
  Widget _buildOtherButton(String? normalizedValue) {
    final isSelected = normalizedValue == 'international';

    return GestureDetector(
      onTap: enabled ? () => onChanged('international') : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.editableBackground : Colors.grey[50],
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.editableBorder : Colors.grey[200]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌍', style: TextStyle(fontSize: 16.sp)),
            SizedBox(width: 6.w),
            Text(
              'foodStyle.international'.tr(),
              style: TextStyle(
                fontSize: 13.sp,
                color: isSelected ? AppColors.primary : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Static helper to get display text for a food style code
  /// Returns "🇰🇷 Style" format
  static String getDisplayText(String? code, BuildContext context) {
    if (code == null || code.isEmpty) return '';
    if (code == 'international') return '🌍 ${'foodStyle.international'.tr()}';

    // Handle legacy codes
    final legacyMap = {
      'ko-KR': 'KR',
      'en-US': 'US',
      'ja-JP': 'JP',
      'zh-CN': 'CN',
      'it-IT': 'IT',
      'es-MX': 'MX',
      'th-TH': 'TH',
      'hi-IN': 'IN',
      'fr-FR': 'FR',
    };
    final normalizedCode = legacyMap[code] ?? code;

    try {
      final country = CountryParser.parseCountryCode(normalizedCode);
      return '${country.flagEmoji} ${'foodStyle.style'.tr()}';
    } catch (_) {
      return code;
    }
  }
}
