import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/domain/entities/hashtag/hashtag.dart';

/// Instagram-style hashtag display widget.
/// Displays hashtags as inline tappable text without background/border.
class HashtagChips extends StatelessWidget {
  final List<Hashtag> hashtags;

  /// Callback when a hashtag is tapped. Receives the hashtag name (without #).
  final ValueChanged<String>? onHashtagTap;

  const HashtagChips({
    super.key,
    required this.hashtags,
    this.onHashtagTap,
  });

  @override
  Widget build(BuildContext context) {
    if (hashtags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8.w,
      runSpacing: 4.h,
      children: hashtags.map((hashtag) => _buildHashtag(hashtag)).toList(),
    );
  }

  Widget _buildHashtag(Hashtag hashtag) {
    return GestureDetector(
      onTap: onHashtagTap != null
          ? () {
              HapticFeedback.selectionClick();
              onHashtagTap!(hashtag.name);
            }
          : null,
      child: Text(
        '#${hashtag.name}',
        style: TextStyle(
          fontSize: 14.sp,
          color: AppColors.primary,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
