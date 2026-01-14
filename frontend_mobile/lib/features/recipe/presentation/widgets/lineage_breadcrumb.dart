import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/app_icons.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';

/// Lineage breadcrumb widget displayed at the TOP of Recipe Detail screen.
/// Shows root and parent recipe links for variant recipes.
class LineageBreadcrumb extends StatelessWidget {
  final RecipeSummary? rootInfo;
  final RecipeSummary? parentInfo;

  const LineageBreadcrumb({
    super.key,
    this.rootInfo,
    this.parentInfo,
  });

  bool get hasLineage => rootInfo != null || parentInfo != null;

  /// Check if parent and root are the same recipe
  bool get _isParentSameAsRoot =>
      rootInfo != null &&
      parentInfo != null &&
      rootInfo!.publicId == parentInfo!.publicId;

  @override
  Widget build(BuildContext context) {
    if (!hasLineage) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border(
          bottom: BorderSide(
            color: Colors.orange[100]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Root recipe link (if exists)
          if (rootInfo != null)
            _buildLineageRow(
              context,
              icon: AppIcons.originalRecipe,
              label: 'recipe.lineage.original'.tr(),
              recipeName: rootInfo!.title,
              creatorName: rootInfo!.creatorName,
              recipeId: rootInfo!.publicId,
              isRoot: true,
            ),
          // Parent recipe link (only if different from root)
          if (parentInfo != null && !_isParentSameAsRoot) ...[
            if (rootInfo != null) SizedBox(height: 6.h),
            _buildLineageRow(
              context,
              icon: Icons.subdirectory_arrow_right,
              label: 'recipe.lineage.parent'.tr(),
              recipeName: parentInfo!.title,
              creatorName: parentInfo!.creatorName,
              recipeId: parentInfo!.publicId,
              isRoot: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLineageRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String recipeName,
    required String creatorName,
    required String recipeId,
    required bool isRoot,
  }) {
    return InkWell(
      onTap: () {
        context.push(RouteConstants.recipeDetailPath(recipeId));
      },
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: Colors.orange[700],
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: isRoot ? Colors.orange[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: isRoot ? Colors.orange[800] : Colors.grey[700],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                recipeName,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              '@$creatorName',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.chevron_right,
              size: 18.sp,
              color: Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }
}
