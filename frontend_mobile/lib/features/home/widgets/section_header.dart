import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Reusable section header with title and optional "See All" action
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final EdgeInsets padding;

  SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    EdgeInsets? padding,
  }) : padding = padding ?? EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 12.h);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'home.seeAll'.tr(),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
