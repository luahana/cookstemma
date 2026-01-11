import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_filter_provider.dart';

/// Sort dropdown for log posts
class SortDropdown extends StatelessWidget {
  final LogSortOption currentSort;
  final ValueChanged<LogSortOption> onChanged;

  const SortDropdown({
    super.key,
    required this.currentSort,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LogSortOption>(
          value: currentSort,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 18.sp,
            color: Colors.grey[600],
          ),
          isDense: true,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
          items: [
            DropdownMenuItem(
              value: LogSortOption.recent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 14.sp, color: Colors.grey[600]),
                  SizedBox(width: 6.w),
                  Text('logPost.filter.sort.recent'.tr()),
                ],
              ),
            ),
            DropdownMenuItem(
              value: LogSortOption.oldest,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 14.sp, color: Colors.grey[600]),
                  SizedBox(width: 6.w),
                  Text('logPost.filter.sort.oldest'.tr()),
                ],
              ),
            ),
            DropdownMenuItem(
              value: LogSortOption.outcomeSuccess,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(LogOutcome.success.emoji, style: TextStyle(fontSize: 12.sp)),
                  SizedBox(width: 6.w),
                  Text('logPost.filter.sort.winsFirst'.tr()),
                ],
              ),
            ),
            DropdownMenuItem(
              value: LogSortOption.outcomeFailed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(LogOutcome.failed.emoji, style: TextStyle(fontSize: 12.sp)),
                  SizedBox(width: 6.w),
                  Text('logPost.filter.sort.lessonsFirst'.tr()),
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
