import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/locale_dropdown.dart';

/// Horizontal scrollable filter chips for culinary locale selection
class LocaleFilterChips extends StatelessWidget {
  final String? selectedLocale;
  final ValueChanged<String?> onLocaleChanged;

  const LocaleFilterChips({
    super.key,
    this.selectedLocale,
    required this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" chip
          _buildChip(
            label: 'locale.all'.tr(),
            isSelected: selectedLocale == null,
            onTap: () => onLocaleChanged(null),
          ),
          const SizedBox(width: 8),
          // Locale chips
          ...CulinaryLocale.options.map((locale) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildChip(
                  label: '${locale.flagEmoji} ${locale.labelKey.tr()}',
                  isSelected: selectedLocale == locale.code,
                  onTap: () => onLocaleChanged(locale.code),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
