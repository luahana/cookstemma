import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Timeline section header for grouping logs by date
/// Shows "TODAY", "YESTERDAY", or formatted date
class JourneyTimelineHeader extends StatelessWidget {
  final DateTime date;
  final int? itemCount;
  final bool showDivider;

  const JourneyTimelineHeader({
    super.key,
    required this.date,
    this.itemCount,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final label = _getDateLabel(date);

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          if (showDivider)
            Expanded(
              flex: 1,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.grey[300]!,
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isToday(date) ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isToday(date) ? AppColors.primary.withValues(alpha: 0.2) : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isToday(date))
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isToday(date) ? AppColors.primary : Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (itemCount != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _isToday(date) ? AppColors.primary.withValues(alpha: 0.2) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            itemCount.toString(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _isToday(date) ? AppColors.primary : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            Expanded(
              flex: 2,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey[300]!,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(targetDate).inDays;

    if (difference == 0) {
      return 'logPost.timeline.today'.tr();
    } else if (difference == 1) {
      return 'logPost.timeline.yesterday'.tr();
    } else if (difference < 7) {
      return 'logPost.timeline.daysAgo'.tr(namedArgs: {'days': difference.toString()});
    } else if (date.year == now.year) {
      // Same year: "Jan 15"
      return DateFormat.MMMd(context.locale.toString()).format(date);
    } else {
      // Different year: "Jan 15, 2024"
      return DateFormat.yMMMd(context.locale.toString()).format(date);
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

/// Helper extension for getting locale from BuildContext
extension _LocaleContext on JourneyTimelineHeader {
  BuildContext get context => throw UnimplementedError();
}

/// Simplified timeline header without context dependency
class SimpleTimelineHeader extends StatelessWidget {
  final DateTime date;
  final int? itemCount;

  const SimpleTimelineHeader({
    super.key,
    required this.date,
    this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final label = _getDateLabel(context, date);
    final isToday = _isToday(date);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isToday ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isToday ? AppColors.primary.withValues(alpha: 0.2) : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isToday)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isToday ? AppColors.primary : Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                if (itemCount != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.primary.withValues(alpha: 0.2) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      itemCount.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isToday ? AppColors.primary : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey[200],
            ),
          ),
        ],
      ),
    );
  }

  String _getDateLabel(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(targetDate).inDays;

    if (difference == 0) {
      return 'logPost.timeline.today'.tr();
    } else if (difference == 1) {
      return 'logPost.timeline.yesterday'.tr();
    } else if (difference < 7) {
      return 'logPost.timeline.daysAgo'.tr(namedArgs: {'days': difference.toString()});
    } else if (date.year == now.year) {
      return DateFormat.MMMd(context.locale.languageCode).format(date);
    } else {
      return DateFormat.yMMMd(context.locale.languageCode).format(date);
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

/// Utility for grouping logs by date
class DateGrouper {
  /// Groups items by date, returning a map of date key to items
  static Map<String, List<T>> groupByDate<T>(
    List<T> items,
    DateTime Function(T) getDate,
  ) {
    final Map<String, List<T>> grouped = {};

    for (final item in items) {
      final date = getDate(item);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      if (grouped.containsKey(key)) {
        grouped[key]!.add(item);
      } else {
        grouped[key] = [item];
      }
    }

    return grouped;
  }

  /// Parses a date key back to DateTime
  static DateTime parseKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
