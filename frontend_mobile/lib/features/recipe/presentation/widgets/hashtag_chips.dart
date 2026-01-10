import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/domain/entities/hashtag/hashtag.dart';

class HashtagChips extends StatelessWidget {
  final List<Hashtag> hashtags;

  const HashtagChips({super.key, required this.hashtags});

  @override
  Widget build(BuildContext context) {
    if (hashtags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: hashtags.map((hashtag) => _buildChip(hashtag)).toList(),
    );
  }

  Widget _buildChip(Hashtag hashtag) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        '#${hashtag.name}',
        style: TextStyle(
          fontSize: 13.sp,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
