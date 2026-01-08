import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/providers/locale_provider.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('settings.title'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // General Settings Section
          _buildSectionHeader('settings.general'.tr()),
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: 'settings.language'.tr(),
            subtitle: _getLanguageDisplayName(currentLocale),
            onTap: () => context.push(RouteConstants.profileEdit),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'settings.notifications'.tr(),
            subtitle: 'settings.notificationsSubtitle'.tr(),
            onTap: () {
              // TODO: Navigate to notifications settings
            },
          ),

          const SizedBox(height: 24),

          // Account Section
          _buildSectionHeader('settings.account'.tr()),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: 'settings.logout'.tr(),
            onTap: () => _showLogoutDialog(context, ref),
          ),

          const SizedBox(height: 24),

          // Danger Zone Section
          _buildSectionHeader(
            'settings.dangerZone'.tr(),
            color: Colors.red[700],
          ),
          _buildSettingsTile(
            context,
            icon: Icons.delete_forever,
            title: 'settings.deleteAccount'.tr(),
            titleColor: Colors.red[700],
            iconColor: Colors.red[700],
            onTap: () => context.push(RouteConstants.deleteAccount),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getLanguageDisplayName(String locale) {
    return switch (locale) {
      'ko-KR' => '한국어',
      'en-US' => 'English',
      _ => locale,
    };
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color ?? Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? const Color(0xFF1A237E)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: titleColor ?? Colors.black87,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              )
            : null,
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('settings.logout'.tr()),
        content: Text('settings.logoutConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(authStateProvider.notifier).logout();
            },
            child: Text(
              'settings.logout'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
