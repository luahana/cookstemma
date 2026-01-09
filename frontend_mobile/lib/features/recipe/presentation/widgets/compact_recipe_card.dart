import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/locale_dropdown.dart';

/// Compact recipe card for grid view
/// Shows essential info: image, title, type badge, variant/log counts
class CompactRecipeCard extends StatelessWidget {
  final RecipeSummary recipe;
  final VoidCallback? onTap;
  final VoidCallback? onLog;
  final VoidCallback? onFork;

  const CompactRecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onLog,
    this.onFork,
  });

  bool get isOriginal => !recipe.isVariant;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${isOriginal ? "Original" : "Variant"}: ${recipe.title}',
      hint: 'Double tap to view',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badges
            _buildImageSection(),
            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name
                  Text(
                    recipe.foodName,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Title
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Stats row
                  _buildStatsRow(),
                  const SizedBox(height: 8),
                  // Action buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: AppCachedImage(
            imageUrl: recipe.thumbnailUrl ?? 'https://via.placeholder.com/200x120',
            width: double.infinity,
            height: 100,
            borderRadius: 0,
          ),
        ),
        // Type badge (top left)
        Positioned(
          top: 6,
          left: 6,
          child: _buildTypeBadge(),
        ),
        // Locale badge (top right)
        Positioned(
          top: 6,
          right: 6,
          child: _buildLocaleBadge(),
        ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isOriginal ? AppColors.textPrimary : AppColors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isOriginal ? '📌' : '🔀',
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _buildLocaleBadge() {
    final locale = CulinaryLocale.fromCode(recipe.culinaryLocale);
    if (locale == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        locale.flagEmoji,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildStatsRow() {
    final hasVariants = recipe.variantCount > 0;
    final hasLogs = recipe.logCount > 0;

    if (!hasVariants && !hasLogs) {
      return const SizedBox(height: 14); // Maintain spacing
    }

    return Row(
      children: [
        if (hasVariants) ...[
          Icon(Icons.call_split, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 2),
          Text(
            recipe.variantCount.toString(),
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
        if (hasVariants && hasLogs) const SizedBox(width: 8),
        if (hasLogs) ...[
          Icon(Icons.edit_note, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 2),
          Text(
            recipe.logCount.toString(),
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _CompactActionButton(
            icon: Icons.edit_note,
            onTap: onLog,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _CompactActionButton(
            icon: Icons.call_split,
            onTap: onFork,
          ),
        ),
      ],
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CompactActionButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

/// Compact recipe card with fixed height for uniform grid
class CompactRecipeCardFixed extends StatelessWidget {
  final RecipeSummary recipe;
  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onLog;
  final VoidCallback? onFork;

  const CompactRecipeCardFixed({
    super.key,
    required this.recipe,
    this.height = 220,
    this.onTap,
    this.onLog,
    this.onFork,
  });

  bool get isOriginal => !recipe.isVariant;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badges - fixed height
            SizedBox(
              height: height * 0.45,
              child: _buildImageSection(),
            ),
            // Content - flexible
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food name
                    Text(
                      recipe.foodName,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Title
                    Expanded(
                      child: Text(
                        recipe.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Stats row
                    _buildStatsRow(),
                    const SizedBox(height: 6),
                    // Action buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: AppCachedImage(
            imageUrl: recipe.thumbnailUrl ?? 'https://via.placeholder.com/200x120',
            width: double.infinity,
            height: double.infinity,
            borderRadius: 0,
          ),
        ),
        // Type badge (top left)
        Positioned(
          top: 6,
          left: 6,
          child: _buildTypeBadge(),
        ),
        // Locale badge (top right)
        Positioned(
          top: 6,
          right: 6,
          child: _buildLocaleBadge(),
        ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isOriginal ? AppColors.textPrimary : AppColors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isOriginal ? '📌' : '🔀',
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _buildLocaleBadge() {
    final locale = CulinaryLocale.fromCode(recipe.culinaryLocale);
    if (locale == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        locale.flagEmoji,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildStatsRow() {
    final hasVariants = recipe.variantCount > 0;
    final hasLogs = recipe.logCount > 0;

    if (!hasVariants && !hasLogs) {
      return const SizedBox(height: 14);
    }

    return Row(
      children: [
        if (hasVariants) ...[
          Icon(Icons.call_split, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 2),
          Text(
            recipe.variantCount.toString(),
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
        if (hasVariants && hasLogs) const SizedBox(width: 8),
        if (hasLogs) ...[
          Icon(Icons.edit_note, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 2),
          Text(
            recipe.logCount.toString(),
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _CompactActionButton(
            icon: Icons.edit_note,
            onTap: onLog,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _CompactActionButton(
            icon: Icons.call_split,
            onTap: onFork,
          ),
        ),
      ],
    );
  }
}
