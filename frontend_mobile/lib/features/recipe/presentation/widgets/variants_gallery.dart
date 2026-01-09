import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';

/// Horizontal scrolling gallery showing variant recipes.
/// Only displayed for root/original recipes that have variants.
class VariantsGallery extends StatelessWidget {
  final List<RecipeSummary> variants;
  final String recipeId;

  const VariantsGallery({
    super.key,
    required this.variants,
    required this.recipeId,
  });

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'recipe.variantsGallery.title'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (variants.length > 3)
                TextButton(
                  onPressed: () {
                    // Navigate to full variants list (future feature)
                  },
                  child: Text(
                    'recipe.variantsGallery.viewAll'.tr(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal scroll gallery
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: variants.length,
            itemBuilder: (context, index) {
              return _buildVariantCard(context, variants[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVariantCard(BuildContext context, RecipeSummary variant) {
    return GestureDetector(
      onTap: () => context.push(RouteConstants.recipeDetailPath(variant.publicId)),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: variant.thumbnailUrl != null
                  ? AppCachedImage(
                      imageUrl: variant.thumbnailUrl!,
                      width: 140,
                      height: 100,
                      borderRadius: 12,
                    )
                  : Container(
                      width: 140,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.grey[400],
                        size: 32,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            // Title (max 2 lines)
            Text(
              variant.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Creator name
            Text(
              "@${variant.creatorName}",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Activity counts
            Row(
              children: [
                Icon(
                  Icons.alt_route,
                  size: 12,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 2),
                Text(
                  "${variant.variantCount}",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.history_edu,
                  size: 12,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 2),
                Text(
                  "${variant.logCount}",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
