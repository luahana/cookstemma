import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              icon: Icons.pin_drop_outlined,
              label: 'recipe.lineage.original'.tr(),
              recipeName: rootInfo!.title,
              creatorName: rootInfo!.creatorName,
              recipeId: rootInfo!.publicId,
              isRoot: true,
            ),
          // Parent recipe link (only if different from root)
          if (parentInfo != null && !_isParentSameAsRoot) ...[
            if (rootInfo != null) const SizedBox(height: 6),
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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.orange[700],
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isRoot ? Colors.orange[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isRoot ? Colors.orange[800] : Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                recipeName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "(by $creatorName)",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }
}
