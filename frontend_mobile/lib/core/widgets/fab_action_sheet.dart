import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
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
              SizedBox(height: 8.h),
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
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14.sp,
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
