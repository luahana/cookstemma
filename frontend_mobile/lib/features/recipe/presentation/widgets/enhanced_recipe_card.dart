import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/app_emojis.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/highlighted_text.dart';
import 'package:pairing_planet2_frontend/core/widgets/stat_badge.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/diff_summary_row.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/ingredient_preview_chips.dart';

/// Enhanced recipe card for the Living Blueprint browse page
/// Shows diff summary for variants
class EnhancedRecipeCard extends StatelessWidget {
  final RecipeSummary recipe;
  final String? searchQuery;
  final List<IngredientPreview>? ingredientPreviews;
  final DiffSummary? diffSummary;
  final VoidCallback? onTap;

  const EnhancedRecipeCard({
    super.key,
    required this.recipe,
    this.searchQuery,
    this.ingredientPreviews,
    this.diffSummary,
    this.onTap,
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
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 4.h),
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
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name and title
                  _buildTitleSection(),
                  SizedBox(height: 8.h),
                  // Description
                  HighlightedText(
                    text: recipe.description,
                    query: searchQuery,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
                  ),
                  // Ingredient preview (if available)
                  if (ingredientPreviews != null && ingredientPreviews!.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    IngredientPreviewChips(
                      ingredients: ingredientPreviews!,
                      showDiffBadges: !isOriginal && diffSummary != null,
                    ),
                  ],
                  // Diff summary for variants
                  if (!isOriginal && diffSummary != null && diffSummary!.hasChanges) ...[
                    SizedBox(height: 12.h),
                    DiffSummaryRow(summary: diffSummary!),
                  ],
                  SizedBox(height: 12.h),
                  // Creator row
                  _buildCreatorRow(context),
                  SizedBox(height: 12.h),
                  // Stats row (log count + variant count)
                  _buildStatsRow(),
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
          height: 180.h,
          borderRadius: 16,
        ),
        // Gradient overlay at bottom for badges
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16.r),
                bottomRight: Radius.circular(16.r),
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
          top: 12.h,
          left: 12.w,
          child: _buildTypeBadge(),
        ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isOriginal ? AppColors.textPrimary : AppColors.primary,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isOriginal ? AppEmojis.recipeOriginal : AppEmojis.recipeVariant,
            style: TextStyle(fontSize: 11.sp),
          ),
          SizedBox(width: 4.w),
          Text(
            isOriginal ? 'recipe.originalBadge'.tr() : 'recipe.variant'.tr(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
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
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        HighlightedText(
          text: recipe.title,
          query: searchQuery,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCreatorRow(BuildContext context) {
    final hasCreatorId = recipe.creatorPublicId != null;

    return GestureDetector(
      onTap: hasCreatorId
          ? () {
              HapticFeedback.selectionClick();
              context.push(RouteConstants.userProfilePath(recipe.creatorPublicId!));
            }
          : null,
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            size: 16.sp,
            color: Colors.grey[400],
          ),
          SizedBox(width: 4.w),
          Text(
            recipe.creatorName,
            style: TextStyle(
              color: hasCreatorId ? AppColors.primary : Colors.grey[600],
              fontSize: 13.sp,
              fontWeight: hasCreatorId ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        // Variant count
        StatBadge(
          icon: Icons.call_split,
          count: recipe.variantCount,
          label: 'grid.variants'.tr(),
        ),
        SizedBox(width: 12.w),
        // Log count
        StatBadge(
          icon: Icons.edit_note,
          count: recipe.logCount,
          label: 'grid.logs'.tr(),
        ),
      ],
    );
  }
}
