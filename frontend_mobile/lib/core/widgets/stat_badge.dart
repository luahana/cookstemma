import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A compact stat badge showing an icon, count, and label
/// Used for displaying metrics like variant count, log count, etc.
class StatBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? textColor;

  const StatBadge({
    super.key,
    required this.icon,
    required this.count,
    required this.label,
    this.iconColor,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: iconColor ?? Colors.grey[600],
          ),
          SizedBox(width: 6.w),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: textColor ?? Colors.grey[700],
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: (textColor ?? Colors.grey[700])?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
