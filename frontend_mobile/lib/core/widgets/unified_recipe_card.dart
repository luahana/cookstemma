import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/app_spacing.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/locale_badge.dart';

/// Unified recipe card for consistent display across app
/// Used in: home page, recipe lists, saved recipes, profile pages
class UnifiedRecipeCard extends ConsumerWidget {
  final RecipeSummary recipe;
  final bool showUsername;
  final bool isVertical;
  final VoidCallback? onTap;

  const UnifiedRecipeCard({
    super.key,
    required this.recipe,
    this.showUsername = true,
    this.isVertical = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user's food style preference to compare
    final userFoodStyle = ref.watch(myProfileProvider).maybeWhen(
          data: (profile) => profile.user.defaultFoodStyle,
          orElse: () => null,
        );

    // Show cook style flag only if different from user preference
    final showCookStyleFlag = recipe.culinaryLocale.isNotEmpty &&
        userFoodStyle != null &&
        userFoodStyle.isNotEmpty &&
        _normalizeLocale(recipe.culinaryLocale) != _normalizeLocale(userFoodStyle);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (onTap != null) {
          onTap!();
        } else {
          context.push(RouteConstants.recipeDetailPath(recipe.publicId));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isVertical
            ? _buildVerticalLayout(showCookStyleFlag)
            : _buildHorizontalLayout(showCookStyleFlag),
      ),
    );
  }

  Widget _buildHorizontalLayout(bool showCookStyleFlag) {
    return Padding(
      padding: EdgeInsets.all(12.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left section - square image
          Expanded(
            child: AspectRatio(
              aspectRatio: AppSpacing.squareAspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: recipe.thumbnailUrl != null && recipe.thumbnailUrl!.isNotEmpty
                    ? AppCachedImage(
                        imageUrl: recipe.thumbnailUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 8.r,
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.restaurant,
                          size: 40.sp,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
          ),

            SizedBox(width: 12.w),

            // Right section - recipe info (50% width)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top content section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Food name (dish name) - always show if available
                      if (recipe.foodName.isNotEmpty) ...[
                        Text(
                          recipe.foodName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                      ],

                      // 2. Recipe title + cooking style flag (inline)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              recipe.title,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[900],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (showCookStyleFlag) ...[
                            SizedBox(width: 4.w),
                            LocaleBadge(
                              localeCode: recipe.culinaryLocale,
                              showLabel: false,
                              fontSize: 12.sp,
                            ),
                          ],
                        ],
                      ),

                      SizedBox(height: 4.h),

                      // 3. Username (hidden on profile page my recipes)
                      if (showUsername && recipe.creatorName.isNotEmpty) ...[
                        Text(
                          recipe.creatorName,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                      ],

                      // 4. Description (truncated)
                      if (recipe.description.isNotEmpty) ...[
                        Text(
                          recipe.description,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                      ],

                      // 5. Hashtags (show first 3)
                      if (recipe.hashtags != null && recipe.hashtags!.isNotEmpty)
                        Text(
                          recipe.hashtags!.take(3).map((h) => '#$h').join(' '),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.hashtag,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),

                  // 6. Metrics row (variants and logs) - fixed at bottom
                  _buildMetricsRow(),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildVerticalLayout(bool showCookStyleFlag) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top section - square image
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
          child: AspectRatio(
            aspectRatio: AppSpacing.squareAspectRatio,
            child: recipe.thumbnailUrl != null && recipe.thumbnailUrl!.isNotEmpty
                ? AppCachedImage(
                    imageUrl: recipe.thumbnailUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 0,
                  )
                : Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.restaurant,
                      size: 40.sp,
                      color: Colors.grey[400],
                    ),
                  ),
          ),
        ),

        // Bottom section - recipe info
        Padding(
          padding: EdgeInsets.all(10.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Food name (dish name) - always show if available
              if (recipe.foodName.isNotEmpty) ...[
                Text(
                  recipe.foodName,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
              ],

              // 2. Recipe title + cooking style flag (inline)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showCookStyleFlag) ...[
                    SizedBox(width: 4.w),
                    LocaleBadge(
                      localeCode: recipe.culinaryLocale,
                      showLabel: false,
                      fontSize: 11.sp,
                    ),
                  ],
                ],
              ),

              SizedBox(height: 4.h),

              // 3. Username (hidden on profile page my recipes)
              if (showUsername && recipe.creatorName.isNotEmpty) ...[
                Text(
                  recipe.creatorName,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
              ],

              // 4. Description (truncated)
              if (recipe.description.isNotEmpty) ...[
                Text(
                  recipe.description,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
              ],

              // 5. Hashtags (show first 3)
              if (recipe.hashtags != null && recipe.hashtags!.isNotEmpty) ...[
                Text(
                  recipe.hashtags!.take(3).map((h) => '#$h').join(' '),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.hashtag,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
              ],

              // 6. Metrics row (variants and logs)
              _buildMetricsRow(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow() {
    final hasVariants = recipe.variantCount > 0;
    final hasLogs = recipe.logCount > 0;

    if (!hasVariants && !hasLogs) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (hasVariants) ...[
          Icon(
            Icons.fork_right,
            size: 14.sp,
            color: Colors.grey[500],
          ),
          SizedBox(width: 4.w),
          Text(
            '${recipe.variantCount}',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),
          if (hasLogs) SizedBox(width: 12.w),
        ],
        if (hasLogs) ...[
          Icon(
            Icons.edit_note,
            size: 14.sp,
            color: Colors.grey[500],
          ),
          SizedBox(width: 4.w),
          Text(
            '${recipe.logCount}',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }

  /// Normalize locale codes for comparison
  /// Handles legacy codes like "ko-KR" and new codes like "KR"
  String _normalizeLocale(String locale) {
    final legacyMap = {
      'ko-KR': 'KR',
      'en-US': 'US',
      'ja-JP': 'JP',
      'zh-CN': 'CN',
      'it-IT': 'IT',
      'es-MX': 'MX',
      'th-TH': 'TH',
      'hi-IN': 'IN',
      'fr-FR': 'FR',
    };
    return legacyMap[locale] ?? locale;
  }
}
