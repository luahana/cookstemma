import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

class MinimalHeader extends StatelessWidget {
  final IconData? icon;
  final String title;
  final bool isRequired;

  const MinimalHeader({
    super.key,
    this.icon,
    required this.title,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.primary, size: 20.sp),
          SizedBox(width: 8.w),
        ],
        Text.rich(
          TextSpan(
            text: title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
            children: [
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16.sp,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
