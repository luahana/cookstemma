import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Standardized box shadow constants for consistent elevation styling.
/// Use these instead of hardcoding BoxShadow values.
class AppShadows {
  AppShadows._();

  // Standard card shadow (most common)
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: Offset(0, 4.h),
        ),
      ];

  // Smaller/subtle shadow
  static List<BoxShadow> get small => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: Offset(0, 2.h),
        ),
      ];

  // Elevated shadow (for floating elements)
  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: Offset(0, 8.h),
        ),
      ];

  // No shadow
  static List<BoxShadow> get none => [];
}
