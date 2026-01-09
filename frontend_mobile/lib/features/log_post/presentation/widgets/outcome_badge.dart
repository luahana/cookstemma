import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Outcome types for cooking logs with associated styling
enum LogOutcome {
  success('SUCCESS', 'logPost.outcome.success', Color(0xFF4CAF50), Color(0xFFE8F5E9)),
  partial('PARTIAL', 'logPost.outcome.partial', Color(0xFFFFC107), Color(0xFFFFF8E1)),
  failed('FAILED', 'logPost.outcome.failed', Color(0xFFF44336), Color(0xFFFFEBEE));

  final String value;
  final String labelKey;
  final Color primaryColor;
  final Color backgroundColor;

  const LogOutcome(this.value, this.labelKey, this.primaryColor, this.backgroundColor);

  String get emoji {
    switch (this) {
      case LogOutcome.success:
        return '\u{1F60A}'; // 😊
      case LogOutcome.partial:
        return '\u{1F610}'; // 😐
      case LogOutcome.failed:
        return '\u{1F622}'; // 😢
    }
  }

  String get label => labelKey.tr();

  static LogOutcome? fromString(String? value) {
    if (value == null) return null;
    return LogOutcome.values.cast<LogOutcome?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Badge variants for different display contexts
enum OutcomeBadgeVariant {
  /// Full badge with emoji and label: [😊 Nailed It!]
  full,
  /// Compact badge with emoji only: [😊]
  compact,
  /// Header style: 😊 SUCCESS (large, for card headers)
  header,
  /// Chip style for filter bar
  chip,
}

/// Styled outcome badge widget for cooking logs
class OutcomeBadge extends StatelessWidget {
  final LogOutcome outcome;
  final OutcomeBadgeVariant variant;
  final bool isSelected;
  final VoidCallback? onTap;

  const OutcomeBadge({
    super.key,
    required this.outcome,
    this.variant = OutcomeBadgeVariant.full,
    this.isSelected = false,
    this.onTap,
  });

  /// Create badge from outcome string value
  factory OutcomeBadge.fromString({
    required String? outcomeValue,
    OutcomeBadgeVariant variant = OutcomeBadgeVariant.full,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    final outcome = LogOutcome.fromString(outcomeValue) ?? LogOutcome.partial;
    return OutcomeBadge(
      outcome: outcome,
      variant: variant,
      isSelected: isSelected,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case OutcomeBadgeVariant.full:
        return _buildFullBadge();
      case OutcomeBadgeVariant.compact:
        return _buildCompactBadge();
      case OutcomeBadgeVariant.header:
        return _buildHeaderBadge();
      case OutcomeBadgeVariant.chip:
        return _buildChipBadge();
    }
  }

  Widget _buildFullBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: outcome.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: outcome.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            outcome.emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 6),
          Text(
            outcome.label,
            style: TextStyle(
              color: outcome.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBadge() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: outcome.backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        outcome.emoji,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildHeaderBadge() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          outcome.emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 8),
        Text(
          outcome.value,
          style: TextStyle(
            color: outcome.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildChipBadge() {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? outcome.primaryColor : outcome.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? outcome.primaryColor : outcome.primaryColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: outcome.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              outcome.emoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 6),
            Text(
              outcome.label,
              style: TextStyle(
                color: isSelected ? Colors.white : outcome.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stats display showing outcome counts: "23 wins · 8 learning · 3 lessons"
class OutcomeStatsRow extends StatelessWidget {
  final int successCount;
  final int partialCount;
  final int failedCount;
  final bool compact;

  const OutcomeStatsRow({
    super.key,
    required this.successCount,
    required this.partialCount,
    required this.failedCount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompactStat(LogOutcome.success, successCount),
          const SizedBox(width: 8),
          _buildCompactStat(LogOutcome.partial, partialCount),
          const SizedBox(width: 8),
          _buildCompactStat(LogOutcome.failed, failedCount),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStat(LogOutcome.success, successCount),
        _buildDivider(),
        _buildStat(LogOutcome.partial, partialCount),
        _buildDivider(),
        _buildStat(LogOutcome.failed, failedCount),
      ],
    );
  }

  Widget _buildStat(LogOutcome outcome, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          outcome.emoji,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            color: outcome.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStat(LogOutcome outcome, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          outcome.emoji,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 2),
        Text(
          count.toString(),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        '\u00B7',
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
