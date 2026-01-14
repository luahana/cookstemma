import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Standardized spacing constants for consistent UI layout.
/// Use these instead of hardcoding SizedBox values.
class AppSpacing {
  AppSpacing._();

  // Vertical spacing (SizedBox with height)
  static SizedBox get verticalXs => SizedBox(height: 4.h);
  static SizedBox get verticalSm => SizedBox(height: 8.h);
  static SizedBox get verticalMd => SizedBox(height: 16.h);
  static SizedBox get verticalLg => SizedBox(height: 24.h);
  static SizedBox get verticalXl => SizedBox(height: 32.h);

  // Horizontal spacing (SizedBox with width)
  static SizedBox get horizontalXs => SizedBox(width: 4.w);
  static SizedBox get horizontalSm => SizedBox(width: 8.w);
  static SizedBox get horizontalMd => SizedBox(width: 16.w);
  static SizedBox get horizontalLg => SizedBox(width: 24.w);

  // Common padding values
  static EdgeInsets get paddingXs => EdgeInsets.all(4.r);
  static EdgeInsets get paddingSm => EdgeInsets.all(8.r);
  static EdgeInsets get paddingMd => EdgeInsets.all(16.r);
  static EdgeInsets get paddingLg => EdgeInsets.all(24.r);

  // Screen/card specific padding
  static EdgeInsets get screenHorizontal =>
      EdgeInsets.symmetric(horizontal: 16.w);
  static EdgeInsets get screenVertical => EdgeInsets.symmetric(vertical: 16.h);
  static EdgeInsets get cardPadding =>
      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h);

  // Image aspect ratios (width:height)
  /// Standard recipe image aspect ratio (4:3)
  /// Used for: recipe detail main photo, log post detail photos
  static const double recipeImageAspectRatio = 4 / 3;

  /// Square aspect ratio (1:1)
  /// Used for: recipe card thumbnails
  static const double squareAspectRatio = 1.0;
}
