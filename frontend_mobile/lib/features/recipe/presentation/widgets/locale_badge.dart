import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'locale_dropdown.dart';

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

    final locale = CulinaryLocale.fromCode(localeCode);
    if (locale == null) {
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
          Text(
            locale.flagEmoji,
            style: TextStyle(fontSize: fontSize.sp),
          ),
          if (showLabel) ...[
            SizedBox(width: 3.w),
            Text(
              locale.labelKey.tr(),
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

    final locale = CulinaryLocale.fromCode(localeCode);
    if (locale == null) {
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
          Text(
            locale.flagEmoji,
            style: TextStyle(fontSize: 16.sp),
          ),
          SizedBox(width: 6.w),
          Text(
            locale.labelKey.tr(),
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
