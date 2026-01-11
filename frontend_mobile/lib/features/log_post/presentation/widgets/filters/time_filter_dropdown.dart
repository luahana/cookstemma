import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_filter_provider.dart';

/// Time filter dropdown
class TimeFilterDropdown extends StatelessWidget {
  final LogTimeFilter currentFilter;
  final ValueChanged<LogTimeFilter> onChanged;

  const TimeFilterDropdown({
    super.key,
    required this.currentFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: currentFilter != LogTimeFilter.all
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: currentFilter != LogTimeFilter.all
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LogTimeFilter>(
          value: currentFilter,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 18.sp,
            color: currentFilter != LogTimeFilter.all
                ? AppColors.primary
                : Colors.grey[600],
          ),
          isDense: true,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: currentFilter != LogTimeFilter.all
                ? AppColors.primary
                : Colors.grey[700],
          ),
          items: [
            DropdownMenuItem(
              value: LogTimeFilter.all,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14.sp, color: Colors.grey[600]),
                  SizedBox(width: 6.w),
                  Text('logPost.filter.time.all'.tr()),
                ],
              ),
            ),
            DropdownMenuItem(
              value: LogTimeFilter.today,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.today, size: 14.sp, color: AppColors.primary),
                  SizedBox(width: 6.w),
                  Text('logPost.filter.time.today'.tr()),
                ],
              ),
            ),
            DropdownMenuItem(
              value: LogTimeFilter.thisWeek,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.date_range, size: 14.sp, color: AppColors.primary),
                  SizedBox(width: 6.w),
                  Text('logPost.filter.time.thisWeek'.tr()),
                ],
              ),
            ),
            DropdownMenuItem(
              value: LogTimeFilter.thisMonth,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month, size: 14.sp, color: AppColors.primary),
                  SizedBox(width: 6.w),
                  Text('logPost.filter.time.thisMonth'.tr()),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}
