import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

class AppTextStyles {
  // 💡 헤드라인 (레시피 제목 등)
  static TextStyle get headline1 => TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  // 💡 서브헤더 (섹션 타이틀 등)
  static TextStyle get subtitle => TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // 💡 본문 (조리법 설명 등)
  static TextStyle get body => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5, // 가독성을 위한 행간
  );

  // 💡 캡션 (날짜, 작성자 정보 등)
  static TextStyle get caption => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
}
