import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Reusable app logo widget displaying the Pairing Planet logo.
/// Shows the icon with optional text.
class AppLogo extends StatelessWidget {
  final double? size;
  final double? fontSize;
  final Color? color;
  final bool showText;

  const AppLogo({
    super.key,
    this.size,
    this.fontSize,
    this.color,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 32.w;
    final textSize = fontSize ?? 18.sp;
    final iconColor = color ?? AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/images/logo_icon.svg',
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
        if (showText) ...[
          SizedBox(width: 8.w),
          Text(
            'Pairing Planet',
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.w700,
              color: AppColors.textLogo,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}
