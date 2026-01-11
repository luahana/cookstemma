import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/widgets/profile_shared.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/browse_filter_provider.dart'
    show RecipeTypeFilter;

/// My Recipes Tab - displays user's own recipes
class MyRecipesTab extends ConsumerStatefulWidget {
  const MyRecipesTab({super.key});

  @override
  ConsumerState<MyRecipesTab> createState() => _MyRecipesTabState();
}

class _MyRecipesTabState extends ConsumerState<MyRecipesTab> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myRecipesProvider);
    final notifier = ref.read(myRecipesProvider.notifier);

    // Initial loading (no cached data)
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error with no data
    if (state.error != null && state.items.isEmpty) {
      return buildProfileErrorState(() {
        ref.read(myRecipesProvider.notifier).refresh();
      });
    }

    // Data available or empty (with filter chips)
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent * 0.8) {
          ref.read(myRecipesProvider.notifier).fetchNextPage();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: buildCacheIndicator(
              isFromCache: state.isFromCache,
              cachedAt: state.cachedAt,
              isLoading: state.isLoading,
            ),
          ),
          // Filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  buildProfileFilterChip(
                    label: 'profile.filter.all'.tr(),
                    isSelected: notifier.currentFilter == RecipeTypeFilter.all,
                    onTap: () => notifier.setFilter(RecipeTypeFilter.all),
                  ),
                  SizedBox(width: 8.w),
                  buildProfileFilterChip(
                    label: 'profile.filter.original'.tr(),
                    isSelected:
                        notifier.currentFilter == RecipeTypeFilter.originals,
                    onTap: () => notifier.setFilter(RecipeTypeFilter.originals),
                  ),
                  SizedBox(width: 8.w),
                  buildProfileFilterChip(
                    label: 'profile.filter.variants'.tr(),
                    isSelected:
                        notifier.currentFilter == RecipeTypeFilter.variants,
                    onTap: () => notifier.setFilter(RecipeTypeFilter.variants),
                  ),
                ],
              ),
            ),
          ),
          // Empty state or list
          if (state.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: buildProfileEmptyState(
                icon: Icons.restaurant_menu,
                message: 'profile.noRecipesYet'.tr(),
                subMessage: 'profile.createRecipe'.tr(),
              ),
            )
          else ...[
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= state.items.length) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.r),
                          child: const CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _buildRecipeCard(context, state.items[index]);
                  },
                  childCount: state.items.length + (state.hasNext ? 1 : 0),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          ],
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, RecipeSummaryDto recipe) {
    return GestureDetector(
      onTap: () =>
          context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
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
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.horizontal(left: Radius.circular(12.r)),
              child: recipe.thumbnail != null
                  ? AppCachedImage(
                      imageUrl: recipe.thumbnail!,
                      width: 100.w,
                      height: 100.h,
                      borderRadius: 0,
                    )
                  : Container(
                      width: 100.w,
                      height: 100.h,
                      color: Colors.grey[200],
                      child: Icon(Icons.restaurant, color: Colors.grey[400]),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      recipe.foodName,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
