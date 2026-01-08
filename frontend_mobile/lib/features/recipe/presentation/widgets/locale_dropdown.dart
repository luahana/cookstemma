import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Culinary locale options for recipe creation
class CulinaryLocale {
  final String code;
  final String flagEmoji;
  final String labelKey; // Translation key

  const CulinaryLocale({
    required this.code,
    required this.flagEmoji,
    required this.labelKey,
  });

  static const List<CulinaryLocale> options = [
    CulinaryLocale(code: 'ko-KR', flagEmoji: '🇰🇷', labelKey: 'locale.korean'),
    CulinaryLocale(code: 'en-US', flagEmoji: '🇺🇸', labelKey: 'locale.american'),
    CulinaryLocale(code: 'ja-JP', flagEmoji: '🇯🇵', labelKey: 'locale.japanese'),
    CulinaryLocale(code: 'zh-CN', flagEmoji: '🇨🇳', labelKey: 'locale.chinese'),
    CulinaryLocale(code: 'it-IT', flagEmoji: '🇮🇹', labelKey: 'locale.italian'),
    CulinaryLocale(code: 'es-MX', flagEmoji: '🇲🇽', labelKey: 'locale.mexican'),
    CulinaryLocale(code: 'th-TH', flagEmoji: '🇹🇭', labelKey: 'locale.thai'),
    CulinaryLocale(code: 'hi-IN', flagEmoji: '🇮🇳', labelKey: 'locale.indian'),
    CulinaryLocale(code: 'fr-FR', flagEmoji: '🇫🇷', labelKey: 'locale.french'),
    CulinaryLocale(code: 'other', flagEmoji: '🌍', labelKey: 'locale.other'),
  ];

  static CulinaryLocale? fromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    return options.firstWhere(
      (o) => o.code == code,
      orElse: () => options.last, // Default to 'other' if not found
    );
  }

  static String getDisplayLabel(String code, BuildContext context) {
    final locale = fromCode(code);
    if (locale == null) return code;
    return '${locale.flagEmoji} ${locale.labelKey.tr()}';
  }
}

/// Dropdown widget for selecting culinary locale
class LocaleDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const LocaleDropdown({
    super.key,
    this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'locale.selectLocale'.tr(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: enabled ? Colors.grey[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                'locale.selectLocale'.tr(),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: enabled ? Colors.grey[700] : Colors.grey[400],
              ),
              items: CulinaryLocale.options.map((locale) {
                return DropdownMenuItem<String>(
                  value: locale.code,
                  child: Text(
                    '${locale.flagEmoji} ${locale.labelKey.tr()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: enabled ? Colors.black : Colors.grey[600],
                    ),
                  ),
                );
              }).toList(),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }
}
