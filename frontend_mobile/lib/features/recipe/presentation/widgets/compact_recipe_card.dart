import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2.h),
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
              padding: EdgeInsets.all(10.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name
                  Text(
                    recipe.foodName,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  // Title
                  Text(
                    recipe.title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  // Stats row
                  _buildStatsRow(),
                  SizedBox(height: 8.h),
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
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12.r),
            topRight: Radius.circular(12.r),
          ),
          child: AppCachedImage(
            imageUrl: recipe.thumbnailUrl ?? 'https://via.placeholder.com/200x120',
            width: double.infinity,
            height: 100.h,
            borderRadius: 0,
          ),
        ),
        // Type badge (top left)
        Positioned(
          top: 6.h,
          left: 6.w,
          child: _buildTypeBadge(),
        ),
        // Locale badge (top right)
        Positioned(
          top: 6.h,
          right: 6.w,
          child: _buildLocaleBadge(),
        ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isOriginal ? AppColors.textPrimary : AppColors.primary,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        isOriginal ? '📌' : '🔀',
        style: TextStyle(fontSize: 10.sp),
      ),
    );
  }

  Widget _buildLocaleBadge() {
    final locale = CulinaryLocale.fromCode(recipe.culinaryLocale);
    if (locale == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        locale.flagEmoji,
        style: TextStyle(fontSize: 12.sp),
      ),
    );
  }

  Widget _buildStatsRow() {
    final hasVariants = recipe.variantCount > 0;
    final hasLogs = recipe.logCount > 0;

    if (!hasVariants && !hasLogs) {
      return SizedBox(height: 14.h); // Maintain spacing
    }

    return Row(
      children: [
        if (hasVariants) ...[
          Icon(Icons.call_split, size: 12.sp, color: Colors.grey[500]),
          SizedBox(width: 2.w),
          Text(
            recipe.variantCount.toString(),
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
        ],
        if (hasVariants && hasLogs) SizedBox(width: 8.w),
        if (hasLogs) ...[
          Icon(Icons.edit_note, size: 12.sp, color: Colors.grey[500]),
          SizedBox(width: 2.w),
          Text(
            recipe.logCount.toString(),
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
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
        SizedBox(width: 4.w),
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
      borderRadius: BorderRadius.circular(6.r),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(6.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Icon(
            icon,
            size: 16.sp,
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
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2.h),
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
                padding: EdgeInsets.all(10.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food name
                    Text(
                      recipe.foodName,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    // Title
                    Expanded(
                      child: Text(
                        recipe.title,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Stats row
                    _buildStatsRow(),
                    SizedBox(height: 6.h),
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
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12.r),
            topRight: Radius.circular(12.r),
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
          top: 6.h,
          left: 6.w,
          child: _buildTypeBadge(),
        ),
        // Locale badge (top right)
        Positioned(
          top: 6.h,
          right: 6.w,
          child: _buildLocaleBadge(),
        ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isOriginal ? AppColors.textPrimary : AppColors.primary,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        isOriginal ? '📌' : '🔀',
        style: TextStyle(fontSize: 10.sp),
      ),
    );
  }

  Widget _buildLocaleBadge() {
    final locale = CulinaryLocale.fromCode(recipe.culinaryLocale);
    if (locale == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        locale.flagEmoji,
        style: TextStyle(fontSize: 12.sp),
      ),
    );
  }

  Widget _buildStatsRow() {
    final hasVariants = recipe.variantCount > 0;
    final hasLogs = recipe.logCount > 0;

    if (!hasVariants && !hasLogs) {
      return SizedBox(height: 14.h);
    }

    return Row(
      children: [
        if (hasVariants) ...[
          Icon(Icons.call_split, size: 12.sp, color: Colors.grey[500]),
          SizedBox(width: 2.w),
          Text(
            recipe.variantCount.toString(),
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
        ],
        if (hasVariants && hasLogs) SizedBox(width: 8.w),
        if (hasLogs) ...[
          Icon(Icons.edit_note, size: 12.sp, color: Colors.grey[500]),
          SizedBox(width: 2.w),
          Text(
            recipe.logCount.toString(),
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
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
        SizedBox(width: 4.w),
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
