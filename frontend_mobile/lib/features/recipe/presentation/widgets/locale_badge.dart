import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Helper to get country from code with legacy support
Country? _getCountry(String? code) {
  if (code == null || code.isEmpty || code == 'international') return null;

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
    return CountryParser.parseCountryCode(normalizedCode);
  } catch (_) {
    return null;
  }
}

/// Compact badge showing culinary locale with flag emoji
class LocaleBadge extends StatelessWidget {
  final String? localeCode;
  final bool showLabel;
  final double fontSize;

  const LocaleBadge({
    super.key,
    this.localeCode,
    this.showLabel = true,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    if (localeCode == null || localeCode!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Handle "other" case
    if (localeCode == 'international') {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4.r),
          border: Border.all(color: Colors.grey[300]!, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌍', style: TextStyle(fontSize: fontSize.sp)),
            if (showLabel) ...[
              SizedBox(width: 3.w),
              Text(
                'foodStyle.style'.tr(),
                style: TextStyle(
                  fontSize: fontSize.sp,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final country = _getCountry(localeCode);
    if (country == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(country.flagEmoji, style: TextStyle(fontSize: fontSize.sp)),
          if (showLabel) ...[
            SizedBox(width: 3.w),
            Text(
              'foodStyle.style'.tr(),
              style: TextStyle(
                fontSize: fontSize.sp,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Larger locale badge for recipe detail screens
class LocaleBadgeLarge extends StatelessWidget {
  final String? localeCode;

  const LocaleBadgeLarge({
    super.key,
    this.localeCode,
  });

  @override
  Widget build(BuildContext context) {
    if (localeCode == null || localeCode!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Handle "other" case
    if (localeCode == 'international') {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌍', style: TextStyle(fontSize: 16.sp)),
            SizedBox(width: 6.w),
            Text(
              'foodStyle.style'.tr(),
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final country = _getCountry(localeCode);
    if (country == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(country.flagEmoji, style: TextStyle(fontSize: 16.sp)),
          SizedBox(width: 6.w),
          Text(
            'foodStyle.style'.tr(),
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Locale badge showing "flag + Style" for recipe detail screens
/// Tappable to toggle between "Style" text and country name
class LocaleBadgeStyled extends StatefulWidget {
  final String? localeCode;

  const LocaleBadgeStyled({super.key, this.localeCode});

  @override
  State<LocaleBadgeStyled> createState() => _LocaleBadgeStyledState();
}

class _LocaleBadgeStyledState extends State<LocaleBadgeStyled> {
  bool _showCountryName = false;

  @override
  Widget build(BuildContext context) {
    if (widget.localeCode == null || widget.localeCode!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Handle "other" case
    if (widget.localeCode == 'international') {
      return GestureDetector(
        onTap: () => setState(() => _showCountryName = !_showCountryName),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🌍', style: TextStyle(fontSize: 12.sp)),
              SizedBox(width: 4.w),
              Text(
                _showCountryName ? 'International' : 'foodStyle.style'.tr(),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final country = _getCountry(widget.localeCode);
    if (country == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => setState(() => _showCountryName = !_showCountryName),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(country.flagEmoji, style: TextStyle(fontSize: 12.sp)),
            SizedBox(width: 4.w),
            Text(
              _showCountryName ? country.name : 'foodStyle.style'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
