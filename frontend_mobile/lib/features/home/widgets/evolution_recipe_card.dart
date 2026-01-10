import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';

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
          horizontal: isCompact ? 0 : 16.w,
          vertical: 6.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2.h),
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
      padding: EdgeInsets.all(12.r),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: recipe.thumbnail != null
                ? AppCachedImage(
                    imageUrl: recipe.thumbnail!,
                    width: 80.w,
                    height: 80.w,
                    borderRadius: 8.r,
                  )
                : Container(
                    width: 80.w,
                    height: 80.w,
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant_menu, color: Colors.grey),
                  ),
          ),
          SizedBox(width: 12.w),
          // Info section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food name
                Text(
                  recipe.foodName,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                // Recipe title
                Text(
                  recipe.title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                // Evolution metrics badges
                _buildEvolutionMetrics(),
              ],
            ),
          ),
          SizedBox(width: 8.w),
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
              child: recipe.thumbnail != null
                  ? AppCachedImage(
                      imageUrl: recipe.thumbnail!,
                      width: double.infinity,
                      height: 100.h,
                      borderRadius: 0,
                    )
                  : Container(
                      width: double.infinity,
                      height: 100.h,
                      color: Colors.orange[100],
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 40.sp,
                        color: Colors.orange[300],
                      ),
                    ),
            ),
          ],
        ),
        // Content
        Padding(
          padding: EdgeInsets.all(10.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food name
              Text(
                recipe.foodName,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              // Recipe title
              Text(
                recipe.title,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8.h),
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
        SizedBox(width: 8.w),
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
        horizontal: small ? 6.w : 8.w,
        vertical: small ? 2.h : 4.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.badgeBackground,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: small ? 12.sp : 14.sp,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: 4.w),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: small ? 10.sp : 11.sp,
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
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
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
                        size: 60.sp,
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
                left: 12.w,
                right: 12.w,
                bottom: 12.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Food name
                    Text(
                      recipe.foodName,
                      style: TextStyle(
                        fontSize: 18.sp,
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
                    SizedBox(height: 4.h),
                    // Recipe title
                    Text(
                      recipe.title,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    // Evolution metrics
                    _buildFeaturedMetrics(),
                  ],
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
        SizedBox(width: 8.w),
        _buildWhiteMetricBadge(Icons.edit_note, logCount),
      ],
    );
  }

  Widget _buildWhiteMetricBadge(IconData icon, int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: Colors.white),
          SizedBox(width: 4.w),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
