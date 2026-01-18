import 'package:flutter/material.dart';

/// Rating for cooking logs (1-5 stars)
/// Replaces the old LogOutcome enum (SUCCESS/PARTIAL/FAILED)
class LogRating {
  final int value; // 1-5

  const LogRating(this.value) : assert(value >= 1 && value <= 5);

  /// Color for the rating stars based on value
  Color get starColor {
    if (value >= 4) return const Color(0xFFFFC107); // Gold
    if (value >= 3) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFBDBDBD); // Grey
  }

  /// Background color for rating display
  Color get backgroundColor {
    if (value >= 4) return const Color(0xFFFFF8E1);
    if (value >= 3) return const Color(0xFFFFF3E0);
    return const Color(0xFFFAFAFA);
  }

  /// Create from nullable int
  static LogRating? fromInt(int? value) {
    if (value == null || value < 1 || value > 5) return null;
    return LogRating(value);
  }

  /// Migration helper: convert old outcome string to rating
  /// SUCCESS → 5, PARTIAL → 3, FAILED → 1
  static LogRating? fromLegacyOutcome(String? outcome) {
    switch (outcome) {
      case 'SUCCESS':
        return const LogRating(5);
      case 'PARTIAL':
        return const LogRating(3);
      case 'FAILED':
        return const LogRating(1);
      default:
        return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogRating &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'LogRating($value)';
}
