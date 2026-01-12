import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Compact level badge for displaying user level
class LevelBadge extends StatelessWidget {
  final int level;
  final String levelName;
  final bool showTitle;

  const LevelBadge({
    super.key,
    required this.level,
    required this.levelName,
    this.showTitle = true,
  });

  Color get _levelColor {
    if (level <= 5) return const Color(0xFF78909C); // Beginner - Grey
    if (level <= 10) return const Color(0xFF4CAF50); // Home Cook - Green
    if (level <= 15) return const Color(0xFF2196F3); // Skilled Cook - Blue
    if (level <= 20) return const Color(0xFF9C27B0); // Home Chef - Purple
    if (level <= 25) return const Color(0xFFFF9800); // Expert Chef - Orange
    return const Color(0xFFFFD700); // Master Chef - Gold
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Level badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: _levelColor,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            'Lv.$level',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        if (showTitle) ...[
          SizedBox(width: 6.w),
          Text(
            'profile.$levelName'.tr(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: _levelColor,
            ),
          ),
        ],
      ],
    );
  }
}
