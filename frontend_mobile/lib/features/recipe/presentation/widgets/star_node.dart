import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';

/// Individual node in the star graph visualization
/// Can be either a root node (center) or variant node (surrounding)
class StarNode extends StatelessWidget {
  final RecipeSummary recipe;
  final bool isRoot;
  final bool isSelected;
  final double size;
  final VoidCallback? onTap;

  const StarNode({
    super.key,
    required this.recipe,
    this.isRoot = false,
    this.isSelected = false,
    this.size = 80,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nodeSize = isRoot ? size * 1.4 : size;

    return Semantics(
      button: true,
      label: isRoot
          ? 'Original recipe: ${recipe.title}'
          : 'Variant: ${recipe.title}',
      hint: 'Double tap to select',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: nodeSize,
        height: nodeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isRoot ? AppColors.textPrimary : Colors.grey[300]!),
            width: isSelected ? 3 : (isRoot ? 3 : 2),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Recipe image
              AppCachedImage(
                imageUrl: recipe.thumbnailUrl ?? 'https://via.placeholder.com/100',
                width: nodeSize,
                height: nodeSize,
                borderRadius: nodeSize / 2,
              ),
              // Gradient overlay for text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              // Root badge
              if (isRoot)
                Positioned(
                  top: 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '📌',
                        style: TextStyle(fontSize: 10.sp),
                      ),
                    ),
                  ),
                ),
              // Variant diff indicator
              if (!isRoot)
                Positioned(
                  top: 4,
                  right: 4,
                  child: _buildDiffIndicator(),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildDiffIndicator() {
    // Show a small indicator of what changed in this variant
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        '🔀',
        style: TextStyle(fontSize: 8.sp),
      ),
    );
  }
}

/// Expanded node card shown when a node is selected
class StarNodeCard extends StatelessWidget {
  final RecipeSummary recipe;
  final bool isRoot;
  final VoidCallback? onTap;
  final VoidCallback? onLog;
  final VoidCallback? onFork;
  final VoidCallback? onViewRecipe;

  const StarNodeCard({
    super.key,
    required this.recipe,
    this.isRoot = false,
    this.onTap,
    this.onLog,
    this.onFork,
    this.onViewRecipe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Recipe image
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: AppCachedImage(
                  imageUrl: recipe.thumbnailUrl ?? 'https://via.placeholder.com/80',
                  width: 80.w,
                  height: 80.w,
                  borderRadius: 12.r,
                ),
              ),
              SizedBox(width: 12.w),
              // Recipe info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge
                    _buildTypeBadge(),
                    SizedBox(height: 4.h),
                    // Food name
                    Text(
                      recipe.foodName,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    // Title
                    Text(
                      recipe.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    // Creator
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14.sp, color: Colors.grey[500]),
                        SizedBox(width: 4.w),
                        Text(
                          recipe.creatorName,
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Stats row for root
          if (isRoot) ...[
            _buildStatsRow(),
            SizedBox(height: 12.h),
          ],
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.visibility_outlined,
                  label: 'star.viewRecipe'.tr(),
                  onTap: onViewRecipe,
                  isPrimary: true,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _ActionButton(
                  icon: Icons.edit_note,
                  label: 'recipe.action.log'.tr(),
                  onTap: onLog,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _ActionButton(
                  icon: Icons.call_split,
                  label: 'recipe.action.fork'.tr(),
                  onTap: onFork,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isRoot ? AppColors.textPrimary : AppColors.primary,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isRoot ? '📌' : '🔀',
            style: TextStyle(fontSize: 10.sp),
          ),
          SizedBox(width: 4.w),
          Text(
            isRoot ? 'recipe.originalBadge'.tr() : 'recipe.variant'.tr(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.call_split, recipe.variantCount, 'star.variants'.tr()),
          Container(width: 1, height: 24.h, color: Colors.grey[300]),
          _buildStatItem(Icons.edit_note, recipe.logCount, 'star.logs'.tr()),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int count, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18.sp, color: AppColors.primary),
        SizedBox(width: 6.w),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: isPrimary ? AppColors.primary : Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18.sp,
                  color: isPrimary ? Colors.white : Colors.grey[700],
                ),
                SizedBox(height: 4.h),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: isPrimary ? Colors.white : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small label shown below star nodes
class StarNodeLabel extends StatelessWidget {
  final String text;
  final bool isRoot;

  const StarNodeLabel({
    super.key,
    required this.text,
    this.isRoot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 80.w),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: isRoot ? AppColors.textPrimary.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: isRoot ? Colors.white : Colors.grey[800],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}
