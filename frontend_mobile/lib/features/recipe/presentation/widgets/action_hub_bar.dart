import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Action Hub Bar - Enhanced bottom action bar
/// High-visibility buttons for "Create Log" and "Create Variation"
class ActionHubBar extends StatelessWidget {
  final VoidCallback onLogPressed;
  final VoidCallback onVariationPressed;
  final bool isLoading;

  const ActionHubBar({
    super.key,
    required this.onLogPressed,
    required this.onVariationPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Log button (outlined/secondary)
          Expanded(
            child: _ActionButton(
              icon: Icons.history_edu,
              title: 'recipe.action.logRecord'.tr(),
              subtitle: 'recipe.action.logSubtitle'.tr(),
              onPressed: isLoading ? null : () {
                HapticFeedback.lightImpact();
                onLogPressed();
              },
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 12),
          // Variation button (filled/primary)
          Expanded(
            child: _ActionButton(
              icon: Icons.fork_right,
              title: 'recipe.action.createVariation'.tr(),
              subtitle: 'recipe.action.variationSubtitle'.tr(),
              onPressed: isLoading ? null : () {
                HapticFeedback.lightImpact();
                onVariationPressed();
              },
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual action button with icon, title, and subtitle
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return _buildPrimaryButton();
    } else {
      return _buildSecondaryButton();
    }
  }

  Widget _buildPrimaryButton() {
    return Material(
      color: Colors.indigo,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.textPrimary, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
