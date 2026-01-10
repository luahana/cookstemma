import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

// 💡 전역적으로 ScaffoldMessenger 상태에 접근하기 위한 키
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class ToastService {
  // 성공 메시지 (초록색 계열)
  static void showSuccess(String message) {
    _showSnackBar(message, backgroundColor: AppColors.growth);
  }

  // 에러 메시지 (빨간색 계열)
  static void showError(String message) {
    _showSnackBar(message, backgroundColor: AppColors.error);
  }

  // 일반 안내 메시지 (오렌지색 계열)
  static void showInfo(String message) {
    _showSnackBar(message, backgroundColor: AppColors.primary);
  }

  static void _showSnackBar(String message, {required Color backgroundColor}) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating, // 하단에 떠 있는 스타일
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
