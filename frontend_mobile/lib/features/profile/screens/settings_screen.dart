import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/providers/locale_provider.dart';
import 'package:pairing_planet2_frontend/core/providers/measurement_preference_provider.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/ingredient_dto.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final measurementPref = ref.watch(measurementPreferenceProvider);

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
          SizedBox(height: 16.h),

          // General Settings Section
          _buildSectionHeader('settings.general'.tr()),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline,
            title: 'profile.editProfile'.tr(),
            subtitle: 'profile.menu.editProfileSubtitle'.tr(),
            onTap: () => context.push(RouteConstants.profileEdit),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.straighten,
            title: 'settings.measurementUnits'.tr(),
            subtitle: _getMeasurementDisplayName(measurementPref, currentLocale),
            onTap: () => _showMeasurementPreferenceDialog(context, ref, measurementPref),
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

          SizedBox(height: 24.h),

          // Account Section
          _buildSectionHeader('settings.account'.tr()),
          _buildSettingsTile(
            context,
            icon: Icons.block,
            title: 'profile.blockedUsers'.tr(),
            subtitle: 'settings.blockedUsersSubtitle'.tr(),
            onTap: () => context.push(RouteConstants.blockedUsers),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: 'settings.logout'.tr(),
            onTap: () => _showLogoutDialog(context, ref),
          ),

          SizedBox(height: 24.h),

          // Legal Section
          _buildSectionHeader('settings.legal'.tr()),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            title: 'legal.termsOfService'.tr(),
            onTap: () => _launchUrl('https://pairingplanet.com/terms'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'legal.privacyPolicy'.tr(),
            onTap: () => _launchUrl('https://pairingplanet.com/privacy'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.code,
            title: 'legal.licenses'.tr(),
            onTap: () => _showLicensePage(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.campaign_outlined,
            title: 'legal.marketingPreferences'.tr(),
            onTap: () => _showMarketingPreferencesDialog(context, ref),
          ),

          SizedBox(height: 40.h),

          // Danger Zone Section - visually separated with red border
          _buildSectionHeader(
            'settings.dangerZone'.tr(),
            color: Colors.red[700],
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red[200]!, width: 1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: _buildDangerTile(
              context,
              icon: Icons.delete_forever,
              title: 'settings.deleteAccount'.tr(),
              subtitle: 'settings.deleteAccountSubtitle'.tr(),
              onTap: () => context.push(RouteConstants.deleteAccount),
            ),
          ),

          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
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
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppColors.textPrimary),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: titleColor ?? Colors.black87,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[600],
                ),
              )
            : null,
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  /// Special tile for danger zone items with red styling
  Widget _buildDangerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.red[700]),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: Colors.red[700],
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: Icon(Icons.chevron_right, color: Colors.red[300]),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
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

  String _getMeasurementDisplayName(MeasurementPreference pref, String locale) {
    if (locale.startsWith('ko')) {
      return pref.displayNameKo;
    }
    return pref.displayName;
  }

  void _showMeasurementPreferenceDialog(
    BuildContext context,
    WidgetRef ref,
    MeasurementPreference current,
  ) {
    final locale = ref.read(localeProvider);
    final isKorean = locale.startsWith('ko');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('settings.measurementUnits'.tr()),
        content: RadioGroup<MeasurementPreference>(
          groupValue: current,
          onChanged: (value) {
            if (value != null) {
              ref.read(measurementPreferenceProvider.notifier).setPreference(value);
              Navigator.pop(dialogContext);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: MeasurementPreference.values.map((pref) {
              return ListTile(
                title: Text(isKorean ? pref.displayNameKo : pref.displayName),
                leading: Radio<MeasurementPreference>(
                  value: pref,
                  activeColor: AppColors.primary,
                ),
                selected: pref == current,
                onTap: () {
                  ref.read(measurementPreferenceProvider.notifier).setPreference(pref);
                  Navigator.pop(dialogContext);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showLicensePage(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Pairing Planet',
      applicationVersion: '1.0.0',
      applicationIcon: Padding(
        padding: EdgeInsets.all(8.r),
        child: Icon(Icons.restaurant_menu, size: 48.sp, color: AppColors.primary),
      ),
    );
  }

  void _showMarketingPreferencesDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => _MarketingPreferencesDialog(ref: ref),
    );
  }
}

class _MarketingPreferencesDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _MarketingPreferencesDialog({required this.ref});

  @override
  ConsumerState<_MarketingPreferencesDialog> createState() =>
      _MarketingPreferencesDialogState();
}

class _MarketingPreferencesDialogState
    extends ConsumerState<_MarketingPreferencesDialog> {
  bool _marketingAgreed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarketingPreference();
  }

  Future<void> _loadMarketingPreference() async {
    final storageService = widget.ref.read(storageServiceProvider);
    final agreed = await storageService.getMarketingAgreed();
    if (mounted) {
      setState(() {
        _marketingAgreed = agreed;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveMarketingPreference(bool value) async {
    setState(() => _marketingAgreed = value);
    final storageService = widget.ref.read(storageServiceProvider);
    await storageService.saveLegalAcceptance(marketingAgreed: value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('legal.marketingPreferences'.tr()),
      content: _isLoading
          ? SizedBox(
              height: 50.h,
              child: const Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text(
                    'legal.agreeToMarketing'.tr(),
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  value: _marketingAgreed,
                  onChanged: _saveMarketingPreference,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primary;
                    }
                    return null;
                  }),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('common.done'.tr()),
        ),
      ],
    );
  }
}
