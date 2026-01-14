import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Reusable clickable username widget that navigates to user profile
class ClickableUsername extends StatelessWidget {
  final String username;
  final String? creatorPublicId;
  final double? fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final bool showAtPrefix;
  final int maxLines;

  const ClickableUsername({
    super.key,
    required this.username,
    this.creatorPublicId,
    this.fontSize,
    this.color,
    this.fontWeight,
    this.showAtPrefix = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final hasCreatorId = creatorPublicId != null;
    final displayText = showAtPrefix ? '@$username' : username;

    return GestureDetector(
      onTap: hasCreatorId
          ? () {
              HapticFeedback.selectionClick();
              context.push(RouteConstants.userProfilePath(creatorPublicId!));
            }
          : null,
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: fontSize ?? 12.sp,
          color: color ?? AppColors.primary,
          fontWeight: fontWeight ?? FontWeight.w500,
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
