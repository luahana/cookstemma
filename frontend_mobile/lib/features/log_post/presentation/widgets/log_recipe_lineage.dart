import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_detail.dart';

/// Recipe lineage widget displayed at the TOP of Log Post Detail screen.
/// Shows which recipe was used and its origin (if it's a variant).
class LogRecipeLineage extends StatelessWidget {
  final LinkedRecipeInfo? linkedRecipe;

  const LogRecipeLineage({
    super.key,
    this.linkedRecipe,
  });

  @override
  Widget build(BuildContext context) {
    if (linkedRecipe == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe that was used (always shown)
          _buildRecipeRow(
            context,
            icon: Icons.restaurant_menu,
            label: "레시피",
            recipeName: linkedRecipe!.title,
            creatorName: linkedRecipe!.creatorName,
            recipeId: linkedRecipe!.publicId,
            isPrimary: true,
          ),
          // Root recipe link (if this recipe is a variant)
          if (linkedRecipe!.isVariant) ...[
            const SizedBox(height: 6),
            _buildRecipeRow(
              context,
              icon: Icons.subdirectory_arrow_right,
              label: "원본",
              recipeName: linkedRecipe!.rootTitle ?? "원본 레시피",
              creatorName: linkedRecipe!.rootCreatorName,
              recipeId: linkedRecipe!.rootPublicId!,
              isPrimary: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecipeRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String recipeName,
    String? creatorName,
    required String recipeId,
    required bool isPrimary,
  }) {
    return InkWell(
      onTap: () {
        context.push('${RouteConstants.recipeDetail}/$recipeId');
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary ? AppColors.primary : Colors.orange[700],
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isPrimary ? AppColors.primary.withValues(alpha: 0.2) : Colors.orange[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? AppColors.primary : Colors.orange[800],
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
            if (creatorName != null) ...[
              const SizedBox(width: 4),
              Text(
                "(by $creatorName)",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
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
