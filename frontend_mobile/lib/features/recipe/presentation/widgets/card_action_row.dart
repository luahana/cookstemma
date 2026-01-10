import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Action buttons for recipe cards: Log, Fork, and View Star/Root
class CardActionRow extends StatelessWidget {
  final bool isOriginal;
  final VoidCallback? onLog;
  final VoidCallback? onFork;
  final VoidCallback? onViewStar;
  final VoidCallback? onViewRoot;

  const CardActionRow({
    super.key,
    required this.isOriginal,
    this.onLog,
    this.onFork,
    this.onViewStar,
    this.onViewRoot,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Log button
        Expanded(
          child: _ActionButton(
            icon: Icons.edit_note,
            label: 'recipe.action.log'.tr(),
            onTap: onLog,
            isPrimary: false,
          ),
        ),
        const SizedBox(width: 8),
        // Fork button
        Expanded(
          child: _ActionButton(
            icon: Icons.call_split,
            label: 'recipe.action.fork'.tr(),
            onTap: onFork,
            isPrimary: false,
          ),
        ),
        const SizedBox(width: 8),
        // View Star (for originals) or View Root (for variants)
        Expanded(
          child: isOriginal
              ? _ActionButton(
                  icon: Icons.star_outline,
                  label: 'recipe.action.star'.tr(),
                  onTap: onViewStar,
                  isPrimary: true,
                )
              : _ActionButton(
                  icon: Icons.push_pin_outlined,
                  label: 'recipe.action.root'.tr(),
                  onTap: onViewRoot,
                  isPrimary: true,
                ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: isPrimary ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isPrimary ? AppColors.primary : Colors.grey[700],
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPrimary ? AppColors.primary : Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact action row for grid view cards
class CompactCardActionRow extends StatelessWidget {
  final VoidCallback? onLog;
  final VoidCallback? onFork;

  const CompactCardActionRow({
    super.key,
    this.onLog,
    this.onFork,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CompactActionButton(
            icon: Icons.edit_note,
            onTap: onLog,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _CompactActionButton(
            icon: Icons.call_split,
            onTap: onFork,
          ),
        ),
      ],
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CompactActionButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Icon(
            icon,
            size: 18,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
