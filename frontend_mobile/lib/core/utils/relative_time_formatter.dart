import 'package:easy_localization/easy_localization.dart';

/// Utility for formatting relative time strings
class RelativeTimeFormatter {
  /// Format a DateTime to a human-readable relative time string
  ///
  /// Examples:
  /// - "Just now" (< 1 minute)
  /// - "5 minutes ago"
  /// - "2 hours ago"
  /// - "3 days ago"
  /// - "Jan 15" (> 7 days)
  static String format(
    DateTime dateTime, {
    bool showMinutes = true,
  }) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (showMinutes && difference.inMinutes < 1) {
      return 'logPost.time.justNow'.tr();
    } else if (showMinutes && difference.inMinutes < 60) {
      return 'logPost.time.minutesAgo'
          .tr(namedArgs: {'count': difference.inMinutes.toString()});
    } else if (difference.inHours < 24) {
      return 'logPost.time.hoursAgo'
          .tr(namedArgs: {'count': difference.inHours.toString()});
    } else if (difference.inDays < 7) {
      return 'logPost.time.daysAgo'
          .tr(namedArgs: {'count': difference.inDays.toString()});
    } else {
      return DateFormat.MMMd().format(dateTime);
    }
  }

  /// Format with default settings (includes minutes)
  static String formatFull(DateTime dateTime) => format(dateTime, showMinutes: true);

  /// Format without minutes granularity (hours/days/date only)
  static String formatCompact(DateTime dateTime) => format(dateTime, showMinutes: false);
}
