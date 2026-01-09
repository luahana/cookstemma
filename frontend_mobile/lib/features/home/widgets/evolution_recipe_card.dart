import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/locale_badge.dart';

/// Evolution-focused recipe card with prominent variant/log badges
class EvolutionRecipeCard extends StatelessWidget {
  final RecipeSummaryDto recipe;
  final bool isCompact;

  const EvolutionRecipeCard({
    super.key,
    required this.recipe,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(RouteConstants.recipeDetailPath(recipe.publicId));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.symmetric(
          horizontal: isCompact ? 0 : 16,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isCompact ? _buildCompactLayout() : _buildFullLayout(),
      ),
    );
  }

  /// Full-width card layout for vertical lists
  Widget _buildFullLayout() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: recipe.thumbnail != null
                ? AppCachedImage(
                    imageUrl: recipe.thumbnail!,
                    width: 80,
                    height: 80,
                    borderRadius: 8,
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant_menu, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 12),
          // Info section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food name + locale badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        recipe.foodName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.indigo[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (recipe.culinaryLocale != null)
                      LocaleBadge(
                        localeCode: recipe.culinaryLocale!,
                        showLabel: false,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Recipe title
                Text(
                  recipe.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Evolution metrics badges
                _buildEvolutionMetrics(),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }

  /// Compact card layout for grids and horizontal scrolls
  Widget _buildCompactLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail with gradient overlay
        Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: recipe.thumbnail != null
                  ? AppCachedImage(
                      imageUrl: recipe.thumbnail!,
                      width: double.infinity,
                      height: 100,
                      borderRadius: 0,
                    )
                  : Container(
                      width: double.infinity,
                      height: 100,
                      color: Colors.orange[100],
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 40,
                        color: Colors.orange[300],
                      ),
                    ),
            ),
            // Locale badge on top right
            if (recipe.culinaryLocale != null)
              Positioned(
                top: 8,
                right: 8,
                child: LocaleBadge(
                  localeCode: recipe.culinaryLocale!,
                  showLabel: false,
                  fontSize: 10,
                ),
              ),
          ],
        ),
        // Content
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food name
              Text(
                recipe.foodName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Recipe title
              Text(
                recipe.title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Evolution metrics
              _buildEvolutionMetrics(small: true),
            ],
          ),
        ),
      ],
    );
  }

  /// Evolution metrics badges (variant count + log count)
  Widget _buildEvolutionMetrics({bool small = false}) {
    final variantCount = recipe.variantCount ?? 0;
    final logCount = recipe.logCount ?? 0;

    return Row(
      children: [
        _buildMetricBadge(
          icon: Icons.fork_right,
          count: variantCount,
          label: 'home.variants'.tr(namedArgs: {'count': variantCount.toString()}),
          small: small,
        ),
        const SizedBox(width: 8),
        _buildMetricBadge(
          icon: Icons.edit_note,
          count: logCount,
          label: 'home.logs'.tr(namedArgs: {'count': logCount.toString()}),
          small: small,
        ),
      ],
    );
  }

  Widget _buildMetricBadge({
    required IconData icon,
    required int count,
    required String label,
    bool small = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.badgeBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: small ? 12 : 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: small ? 10 : 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Large featured card for Bento grid
class FeaturedEvolutionCard extends StatelessWidget {
  final RecipeSummaryDto recipe;

  const FeaturedEvolutionCard({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(RouteConstants.recipeDetailPath(recipe.publicId));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              recipe.thumbnail != null
                  ? AppCachedImage(
                      imageUrl: recipe.thumbnail!,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 0,
                    )
                  : Container(
                      color: Colors.orange[200],
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 60,
                        color: Colors.orange[400],
                      ),
                    ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.overlayGradientEnd,
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              // Content
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Food name
                    Text(
                      recipe.foodName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Recipe title
                    Text(
                      recipe.title,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Evolution metrics
                    _buildFeaturedMetrics(),
                  ],
                ),
              ),
              // Locale badge
              if (recipe.culinaryLocale != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: LocaleBadge(
                    localeCode: recipe.culinaryLocale!,
                    showLabel: false,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedMetrics() {
    final variantCount = recipe.variantCount ?? 0;
    final logCount = recipe.logCount ?? 0;

    return Row(
      children: [
        _buildWhiteMetricBadge(Icons.fork_right, variantCount),
        const SizedBox(width: 8),
        _buildWhiteMetricBadge(Icons.edit_note, logCount),
      ],
    );
  }

  Widget _buildWhiteMetricBadge(IconData icon, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
