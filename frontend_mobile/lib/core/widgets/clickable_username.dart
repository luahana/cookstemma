import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Reusable clickable username widget that navigates to user profile
class ClickableUsername extends StatelessWidget {
  final String username;
  final String? userPublicId;
  final double? fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final bool showAtPrefix;
  final bool showPersonIcon;
  final int maxLines;

  const ClickableUsername({
    super.key,
    required this.username,
    this.userPublicId,
    this.fontSize,
    this.color,
    this.fontWeight,
    this.showAtPrefix = false,
    this.showPersonIcon = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final hasUserId = userPublicId != null;
    // Show @ prefix if either showAtPrefix or showPersonIcon is true
    final shouldShowAt = showAtPrefix || showPersonIcon;
    final displayText = shouldShowAt ? '@$username' : username;
    final effectiveColor = color ?? AppColors.secondary;
    final effectiveFontSize = fontSize ?? 12.sp;

    return GestureDetector(
      onTap: hasUserId
          ? () {
              HapticFeedback.selectionClick();
              context.push(RouteConstants.userProfilePath(userPublicId!));
            }
          : null,
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: effectiveFontSize,
          color: effectiveColor,
          fontWeight: fontWeight ?? FontWeight.w500,
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
