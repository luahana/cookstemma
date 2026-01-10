import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';

class LoginPromptSheet extends ConsumerWidget {
  final String actionKey;
  final VoidCallback? pendingAction;

  const LoginPromptSheet({
    super.key,
    required this.actionKey,
    this.pendingAction,
  });

  /// Show the login prompt bottom sheet
  /// [actionKey] is the translation key for the action (e.g., 'guest.signInToSave')
  /// [pendingAction] is the callback to execute after successful login
  static Future<bool?> show({
    required BuildContext context,
    required String actionKey,
    VoidCallback? pendingAction,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => LoginPromptSheet(
        actionKey: actionKey,
        pendingAction: pendingAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 24.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // Icon
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 32.sp,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 16.h),
            // Title
            Text(
              'guest.signInRequired'.tr(),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            // Subtitle - the action-specific message
            Text(
              actionKey.tr(),
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            // Sign in button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () {
                  // Set pending action if provided
                  if (pendingAction != null) {
                    ref.read(authStateProvider.notifier).setPendingAction(pendingAction!);
                  }
                  Navigator.pop(context, true);
                  context.push(RouteConstants.login);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text('guest.signIn'.tr()),
              ),
            ),
            SizedBox(height: 12.h),
            // Continue as guest button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'guest.continueAsGuest'.tr(),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
