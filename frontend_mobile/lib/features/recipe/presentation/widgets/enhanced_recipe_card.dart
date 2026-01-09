import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/highlighted_text.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/card_action_row.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/diff_summary_row.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/ingredient_preview_chips.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/locale_badge.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/star_preview_badge.dart';

/// Enhanced recipe card for the Living Blueprint browse page
/// Shows star metrics for originals, diff summary for variants
class EnhancedRecipeCard extends StatelessWidget {
  final RecipeSummary recipe;
  final String? searchQuery;
  final List<IngredientPreview>? ingredientPreviews;
  final DiffSummary? diffSummary;
  final VoidCallback? onTap;
  final VoidCallback? onLog;
  final VoidCallback? onFork;
  final VoidCallback? onViewStar;
  final VoidCallback? onViewRoot;

  const EnhancedRecipeCard({
    super.key,
    required this.recipe,
    this.searchQuery,
    this.ingredientPreviews,
    this.diffSummary,
    this.onTap,
    this.onLog,
    this.onFork,
    this.onViewStar,
    this.onViewRoot,
  });

  bool get isOriginal => !recipe.isVariant;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${isOriginal ? "Original" : "Variant"} recipe: ${recipe.title} by ${recipe.creatorName}',
      hint: 'Double tap to view details',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image header with badges
            _buildImageHeader(),
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name and title
                  _buildTitleSection(),
                  const SizedBox(height: 8),
                  // Description
                  HighlightedText(
                    text: recipe.description,
                    query: searchQuery,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  // Ingredient preview (if available)
                  if (ingredientPreviews != null && ingredientPreviews!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    IngredientPreviewChips(
                      ingredients: ingredientPreviews!,
                      showDiffBadges: !isOriginal && diffSummary != null,
                    ),
                  ],
                  // Diff summary for variants
                  if (!isOriginal && diffSummary != null && diffSummary!.hasChanges) ...[
                    const SizedBox(height: 12),
                    DiffSummaryRow(summary: diffSummary!),
                  ],
                  const SizedBox(height: 12),
                  // Creator row
                  _buildCreatorRow(),
                  const SizedBox(height: 12),
                  // Action buttons
                  CardActionRow(
                    isOriginal: isOriginal,
                    onLog: onLog,
                    onFork: onFork,
                    onViewStar: onViewStar,
                    onViewRoot: onViewRoot,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildImageHeader() {
    return Stack(
      children: [
        // Hero image
        AppCachedImage(
          imageUrl: recipe.thumbnailUrl ?? 'https://via.placeholder.com/400x200',
          width: double.infinity,
          height: 180,
          borderRadius: 16,
        ),
        // Gradient overlay at bottom for badges
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
        ),
        // Original/Variant badge (top left)
        Positioned(
          top: 12,
          left: 12,
          child: _buildTypeBadge(),
        ),
        // Locale badge (top right)
        Positioned(
          top: 12,
          right: 12,
          child: LocaleBadge(
            localeCode: recipe.culinaryLocale,
            showLabel: false,
          ),
        ),
        // Star preview (bottom left) for originals
        // Or Based on badge (bottom left) for variants
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: isOriginal
              ? StarPreviewBadge(
                  variantCount: recipe.variantCount,
                  logCount: recipe.logCount,
                )
              : (recipe.rootTitle != null
                  ? BasedOnBadge(
                      rootTitle: recipe.rootTitle!,
                      onTap: onViewRoot,
                    )
                  : const SizedBox.shrink()),
        ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOriginal ? AppColors.textPrimary : AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isOriginal ? '📌' : '🔀',
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(width: 4),
          Text(
            isOriginal ? 'recipe.originalBadge'.tr() : 'recipe.variant'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HighlightedText(
          text: recipe.foodName,
          query: searchQuery,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        HighlightedText(
          text: recipe.title,
          query: searchQuery,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCreatorRow() {
    return Row(
      children: [
        Icon(
          Icons.person_outline,
          size: 16,
          color: Colors.grey[400],
        ),
        const SizedBox(width: 4),
        Text(
          recipe.creatorName,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        if (recipe.logCount > 0) ...[
          Text(
            " · ",
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          Text(
            'recipe.logCountLabel'.tr(namedArgs: {'count': recipe.logCount.toString()}),
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ],
    );
  }
}
