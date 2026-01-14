import 'package:flutter/material.dart';

class AppColors {
  // 💡 브랜드 주색상 (오렌지)
  static const Color primary = Color(0xFFE67E22);
  static const Color primaryLight = Color(0xFFFFE0B2);
  static const Color secondary = Color(0xFF5D4037);

  // 💡 포인트/성장 색상 (초록 - '살아있는' 느낌 강조)
  static const Color growth = Color(0xFF27AE60);

  // 💡 무채색 계열
  static const Color background = Color(0xFFF9F9F9);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textLogo = Color(0xFF494F57);
  static const Color error = Color(0xFFD63031);

  // 💡 기타 (별점, 로그 구분 등)
  static const Color rating = Color(0xFFF1C40F);
  static const Color border = Color(0xFFDFE6E9);

  // 💡 해시태그 색상
  static const Color hashtag = Color(0xFF4CAF50);

  // 💡 검색 하이라이트
  static const Color highlightBackground = Color(0xFFFFF3E0);

  // 💡 Shimmer & Badges
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color badgeBackground = Color(0xFFF5F5F5);
  static const Color overlayGradientEnd = Color(0xCC000000);

  // 💡 Living Blueprint: Diff colors
  static const Color diffAdded = Color(0xFF27AE60);       // Green
  static const Color diffRemoved = Color(0xFFE74C3C);     // Red
  static const Color diffModified = Color(0xFFF39C12);    // Orange
  static const Color diffAddedBg = Color(0xFFE8F5E9);     // Light green
  static const Color diffRemovedBg = Color(0xFFFFEBEE);   // Light red
  static const Color diffModifiedBg = Color(0xFFFFF3E0);  // Light orange

  // 💡 Variation mode: editable/interactive elements
  static const Color editableBackground = Color(0xFFFFF3E0);  // Orange[50] - editable textbox bg
  static const Color editableBorder = Color(0xFFFFE0B2);      // Orange[100] - editable textbox border
  static const Color inheritedInteractive = Color(0xFFFFB74D); // Orange[300] - less saturated, interactive buttons on inherited items
}
