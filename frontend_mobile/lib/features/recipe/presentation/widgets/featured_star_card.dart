import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/locale_dropdown.dart';

/// Large featured card for recipes with many variants (Star recipes)
/// Used in Bento grid layout to highlight popular original recipes
class FeaturedStarCard extends StatelessWidget {
  final RecipeSummary recipe;
  final VoidCallback? onTap;
  final VoidCallback? onLog;
  final VoidCallback? onFork;
  final VoidCallback? onViewStar;

  const FeaturedStarCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onLog,
    this.onFork,
    this.onViewStar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large image with overlays
            Expanded(
              flex: 3,
              child: _buildImageSection(),
            ),
            // Content section
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(14.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food name
                    Text(
                      recipe.foodName,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    // Title
                    Expanded(
                      child: Text(
                        recipe.title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // Creator info
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14.sp, color: Colors.grey[500]),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            recipe.creatorName,
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
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
        // Hero image
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
          ),
          child: AppCachedImage(
            imageUrl: recipe.thumbnailUrl ?? 'https://via.placeholder.com/400x250',
            width: double.infinity,
            height: double.infinity,
            borderRadius: 0,
          ),
        ),
        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ),
        // Featured badge (top left)
        Positioned(
          top: 10.h,
          left: 10.w,
          child: _buildFeaturedBadge(),
        ),
        // Locale badge (top right)
        Positioned(
          top: 10.h,
          right: 10.w,
          child: _buildLocaleBadge(),
        ),
        // Star metrics (bottom)
        Positioned(
          bottom: 10.h,
          left: 10.w,
          right: 10.w,
          child: _buildStarMetrics(),
        ),
      ],
    );
  }

  Widget _buildFeaturedBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⭐', style: TextStyle(fontSize: 12.sp)),
          SizedBox(width: 4.w),
          Text(
            'recipe.starLabel'.tr(),
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

  Widget _buildLocaleBadge() {
    final locale = CulinaryLocale.fromCode(recipe.culinaryLocale);
    if (locale == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(6.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(locale.flagEmoji, style: TextStyle(fontSize: 14.sp)),
          SizedBox(width: 4.w),
          Text(
            locale.labelKey.tr(),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarMetrics() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMetricItem(Icons.call_split, recipe.variantCount, 'grid.variants'.tr()),
          SizedBox(width: 16.w),
          _buildMetricItem(Icons.edit_note, recipe.logCount, 'grid.logs'.tr()),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, int count, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.sp, color: AppColors.primary),
        SizedBox(width: 4.w),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _FeaturedActionButton(
            icon: Icons.edit_note,
            label: 'recipe.action.log'.tr(),
            onTap: onLog,
            isPrimary: false,
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: _FeaturedActionButton(
            icon: Icons.call_split,
            label: 'recipe.action.fork'.tr(),
            onTap: onFork,
            isPrimary: false,
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: _FeaturedActionButton(
            icon: Icons.star_outline,
            label: 'recipe.action.star'.tr(),
            onTap: onViewStar,
            isPrimary: true,
          ),
        ),
      ],
    );
  }
}

class _FeaturedActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _FeaturedActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18.sp,
                color: isPrimary ? AppColors.primary : Colors.grey[600],
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? AppColors.primary : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal featured card variant for carousels
class FeaturedStarCardHorizontal extends StatelessWidget {
  final RecipeSummary recipe;
  final double width;
  final VoidCallback? onTap;

  const FeaturedStarCardHorizontal({
    super.key,
    required this.recipe,
    this.width = 280,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 160.h,
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: AppCachedImage(
                imageUrl: recipe.thumbnailUrl ?? 'https://via.placeholder.com/280x160',
                width: width,
                height: 160.h,
                borderRadius: 12,
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Star badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('⭐', style: TextStyle(fontSize: 10.sp)),
                        SizedBox(width: 4.w),
                        Text(
                          '${recipe.variantCount} ${'grid.variants'.tr()}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    recipe.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  // Creator
                  Text(
                    'by ${recipe.creatorName}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
