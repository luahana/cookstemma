import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Compact recipe lineage breadcrumb for log cards
/// Shows: 📍 Recipe Title → variant of "Root Title"
class RecipeLineageBreadcrumb extends StatelessWidget {
  final String recipeTitle;
  final String recipePublicId;
  final String? rootTitle;
  final String? rootPublicId;
  final bool isCompact;
  final VoidCallback? onRecipeTap;
  final VoidCallback? onRootTap;

  const RecipeLineageBreadcrumb({
    super.key,
    required this.recipeTitle,
    required this.recipePublicId,
    this.rootTitle,
    this.rootPublicId,
    this.isCompact = false,
    this.onRecipeTap,
    this.onRootTap,
  });

  bool get isVariant => rootPublicId != null && rootTitle != null;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactBreadcrumb(context);
    }
    return _buildFullBreadcrumb(context);
  }

  Widget _buildCompactBreadcrumb(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (onRecipeTap != null) {
          onRecipeTap!();
        } else {
          context.push(RouteConstants.recipeDetailPath(recipePublicId));
        }
      },
      child: Row(
        children: [
          Icon(
            Icons.pin_drop_outlined,
            size: 14.sp,
            color: AppColors.primary,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              recipeTitle,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 16.sp,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildFullBreadcrumb(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main recipe link
          _buildRecipeLink(
            context: context,
            icon: Icons.pin_drop,
            label: 'logPost.lineage.recipe'.tr(),
            title: recipeTitle,
            publicId: recipePublicId,
            isPrimary: true,
            onTap: onRecipeTap,
          ),
          // Variant info (if applicable)
          if (isVariant) ...[
            SizedBox(height: 8.h),
            _buildVariantIndicator(context),
          ],
        ],
      ),
    );
  }

  Widget _buildRecipeLink({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String title,
    required String publicId,
    required bool isPrimary,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: true,
      label: '$label: $title',
      hint: 'logPost.lineage.tapToView'.tr(),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          if (onTap != null) {
            onTap();
          } else {
            context.push(RouteConstants.recipeDetailPath(publicId));
          }
        },
        borderRadius: BorderRadius.circular(6.r),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: isPrimary ? AppColors.primary : Colors.orange[600],
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: isPrimary ? AppColors.primary.withValues(alpha: 0.2) : Colors.orange[100],
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? AppColors.primary : Colors.orange[800],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20.sp,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantIndicator(BuildContext context) {
    return Semantics(
      button: true,
      label: 'logPost.lineage.variantOf'.tr(namedArgs: {'title': rootTitle!}),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          if (onRootTap != null) {
            onRootTap!();
          } else if (rootPublicId != null) {
            context.push(RouteConstants.recipeDetailPath(rootPublicId!));
          }
        },
        borderRadius: BorderRadius.circular(6.r),
        child: Row(
          children: [
            SizedBox(width: 26.w), // Indent to align with recipe title
            Icon(
              Icons.subdirectory_arrow_right,
              size: 16.sp,
              color: Colors.orange[600],
            ),
            SizedBox(width: 4.w),
            Text(
              'logPost.lineage.variantOf'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                '"$rootTitle"',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16.sp,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple inline lineage for compact cards
class InlineRecipeLineage extends StatelessWidget {
  final String recipeTitle;
  final String? rootTitle;

  const InlineRecipeLineage({
    super.key,
    required this.recipeTitle,
    this.rootTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.pin_drop_outlined,
          size: 12.sp,
          color: AppColors.primary,
        ),
        SizedBox(width: 4.w),
        Flexible(
          child: Text(
            recipeTitle,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (rootTitle != null) ...[
          SizedBox(width: 4.w),
          Icon(
            Icons.subdirectory_arrow_right,
            size: 10.sp,
            color: Colors.orange[500],
          ),
        ],
      ],
    );
  }
}
