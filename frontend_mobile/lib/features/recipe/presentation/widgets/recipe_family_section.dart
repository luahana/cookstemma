import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';

/// Recipe Family Section - Star Layout
/// Shows root recipe prominently with all variants as direct siblings
class RecipeFamilySection extends StatelessWidget {
  final RecipeSummary rootInfo;
  final List<RecipeSummary> allVariants;
  final String currentRecipeId;

  const RecipeFamilySection({
    super.key,
    required this.rootInfo,
    required this.allVariants,
    required this.currentRecipeId,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out current recipe from variants list
    final siblingVariants = allVariants
        .where((v) => v.publicId != currentRecipeId)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.account_tree_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'recipe.family.title'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Root recipe card
          _RootRecipeCard(rootInfo: rootInfo),
          // Sibling variants
          if (siblingVariants.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Text(
                    'recipe.family.otherVariations'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.badgeBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${siblingVariants.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: siblingVariants.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < siblingVariants.length - 1 ? 10 : 0,
                    ),
                    child: _VariantMiniCard(
                      variant: siblingVariants[index],
                      isCurrentRecipe: false,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Root recipe card - prominent display
class _RootRecipeCard extends StatelessWidget {
  final RecipeSummary rootInfo;

  const _RootRecipeCard({required this.rootInfo});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(RouteConstants.recipeDetailPath(rootInfo.publicId));
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Root badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pin_drop_outlined, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'recipe.family.basedOn'.tr(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Root recipe info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rootInfo.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rootInfo.foodName,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Navigate icon
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini card for variant in horizontal list
class _VariantMiniCard extends StatelessWidget {
  final RecipeSummary variant;
  final bool isCurrentRecipe;

  const _VariantMiniCard({
    required this.variant,
    required this.isCurrentRecipe,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCurrentRecipe
          ? null
          : () {
              HapticFeedback.lightImpact();
              context.push(RouteConstants.recipeDetailPath(variant.publicId));
            },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: isCurrentRecipe ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCurrentRecipe ? AppColors.primary : AppColors.border,
            width: isCurrentRecipe ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
              child: SizedBox(
                width: 50,
                height: double.infinity,
                child: variant.thumbnailUrl != null && variant.thumbnailUrl!.isNotEmpty
                    ? AppCachedImage(
                        imageUrl: variant.thumbnailUrl!,
                        width: 50,
                        height: double.infinity,
                        borderRadius: 0,
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, size: 20, color: Colors.grey),
                      ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      variant.title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isCurrentRecipe ? AppColors.primary : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Creator
                    Text(
                      '@${variant.creatorName}',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Current badge
                    if (isCurrentRecipe) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'recipe.family.current'.tr(),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
