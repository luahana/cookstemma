import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'locale_dropdown.dart';

/// Compact badge showing culinary locale with flag emoji
class LocaleBadge extends StatelessWidget {
  final String? localeCode;
  final bool showLabel;
  final double fontSize;

  const LocaleBadge({
    super.key,
    this.localeCode,
    this.showLabel = true,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    if (localeCode == null || localeCode!.isEmpty) {
      return const SizedBox.shrink();
    }

    final locale = CulinaryLocale.fromCode(localeCode);
    if (locale == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            locale.flagEmoji,
            style: TextStyle(fontSize: fontSize),
          ),
          if (showLabel) ...[
            const SizedBox(width: 3),
            Text(
              locale.labelKey.tr(),
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Larger locale badge for recipe detail screens
class LocaleBadgeLarge extends StatelessWidget {
  final String? localeCode;

  const LocaleBadgeLarge({
    super.key,
    this.localeCode,
  });

  @override
  Widget build(BuildContext context) {
    if (localeCode == null || localeCode!.isEmpty) {
      return const SizedBox.shrink();
    }

    final locale = CulinaryLocale.fromCode(localeCode);
    if (locale == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            locale.flagEmoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            locale.labelKey.tr(),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
