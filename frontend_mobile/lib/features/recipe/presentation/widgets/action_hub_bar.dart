import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/constants/app_icons.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Action Hub Bar - Compact bottom action bar
/// Buttons for "Start Cooking", "Create Log" and "Create Variation"
class ActionHubBar extends StatelessWidget {
  final VoidCallback? onCookingPressed;
  final VoidCallback onLogPressed;
  final VoidCallback onVariationPressed;
  final bool isLoading;

  const ActionHubBar({
    super.key,
    this.onCookingPressed,
    required this.onLogPressed,
    required this.onVariationPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 8.h,
        bottom: MediaQuery.of(context).padding.bottom + 8.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cooking mode button (prominent)
          if (onCookingPressed != null) ...[
            Expanded(
              child: _ActionButton(
                icon: Icons.restaurant_menu,
                title: 'cooking.startCooking'.tr(),
                onPressed: isLoading ? null : () {
                  HapticFeedback.mediumImpact();
                  onCookingPressed!();
                },
                isPrimary: true,
                isAccent: true,
              ),
            ),
            SizedBox(width: 8.w),
          ],
          // Variation button (filled/primary)
          Expanded(
            child: _ActionButton(
              icon: AppIcons.variantCreate,
              title: 'recipe.action.createVariation'.tr(),
              onPressed: isLoading ? null : () {
                HapticFeedback.lightImpact();
                onVariationPressed();
              },
              isPrimary: true,
            ),
          ),
          SizedBox(width: 8.w),
          // Log button (outlined/secondary)
          Expanded(
            child: _ActionButton(
              icon: AppIcons.logPost,
              title: 'recipe.action.logRecord'.tr(),
              onPressed: isLoading ? null : () {
                HapticFeedback.lightImpact();
                onLogPressed();
              },
              isPrimary: false,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact single-line action button with icon and title
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isAccent;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.onPressed,
    required this.isPrimary,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isAccent) {
      return _buildAccentButton();
    } else if (isPrimary) {
      return _buildPrimaryButton();
    } else {
      return _buildSecondaryButton();
    }
  }

  Widget _buildAccentButton() {
    return Material(
      color: AppColors.growth,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18.sp),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.textPrimary, size: 20.sp),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
