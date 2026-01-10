import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Bottom sheet that shows action options when FAB is tapped
class FabActionSheet extends StatelessWidget {
  final VoidCallback onNewRecipe;
  final VoidCallback onQuickLog;

  const FabActionSheet({
    super.key,
    required this.onNewRecipe,
    required this.onQuickLog,
  });

  /// Show the action sheet as a modal bottom sheet
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onNewRecipe,
    required VoidCallback onQuickLog,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => FabActionSheet(
        onNewRecipe: onNewRecipe,
        onQuickLog: onQuickLog,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // New Recipe option
              _ActionTile(
                icon: Icons.edit_note,
                title: 'speedDial.newRecipe'.tr(),
                subtitle: 'fabAction.newRecipeSubtitle'.tr(),
                onTap: () {
                  Navigator.pop(context);
                  onNewRecipe();
                },
              ),
              const SizedBox(height: 8),
              // Quick Log option
              _ActionTile(
                icon: Icons.camera_alt,
                title: 'speedDial.quickLog'.tr(),
                subtitle: 'fabAction.quickLogSubtitle'.tr(),
                onTap: () {
                  Navigator.pop(context);
                  onQuickLog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual action tile with icon, title, and subtitle
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
