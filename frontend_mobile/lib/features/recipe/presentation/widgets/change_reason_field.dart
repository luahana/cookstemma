import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Field for entering the reason for creating a recipe variation
class ChangeReasonField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onChanged;

  const ChangeReasonField({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.inheritedInteractive, size: 20.sp),
            SizedBox(width: 8.w),
            Text.rich(
              TextSpan(
                text: 'recipe.changeReasonRequired'.tr(),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red, fontSize: 16.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.editableBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.editableBorder),
          ),
          child: TextField(
            controller: controller,
            onChanged: (_) => onChanged?.call(),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'recipe.changeReasonHint'.tr(),
              hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
