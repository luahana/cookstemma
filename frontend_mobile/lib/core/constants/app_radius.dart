import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Standardized border radius constants for consistent UI styling.
/// Use these instead of hardcoding BorderRadius.circular values.
class AppRadius {
  AppRadius._();

  // Standard border radius values
  static BorderRadius get xs => BorderRadius.circular(4.r);
  static BorderRadius get sm => BorderRadius.circular(8.r);
  static BorderRadius get md => BorderRadius.circular(12.r);
  static BorderRadius get lg => BorderRadius.circular(16.r);
  static BorderRadius get xl => BorderRadius.circular(24.r);

  // Special shapes
  static BorderRadius get pill => BorderRadius.circular(100.r);
  static BorderRadius get sheet =>
      BorderRadius.vertical(top: Radius.circular(24.r));
  static BorderRadius get card => BorderRadius.circular(12.r);

  // Top-only radius (for bottom sheets, modals)
  static BorderRadius get topMd =>
      BorderRadius.vertical(top: Radius.circular(12.r));
  static BorderRadius get topLg =>
      BorderRadius.vertical(top: Radius.circular(16.r));
}
