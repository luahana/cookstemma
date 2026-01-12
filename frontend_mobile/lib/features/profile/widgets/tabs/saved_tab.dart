import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/log_post_card.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/widgets/profile_shared.dart';

/// Saved Tab - displays saved recipes and logs
class SavedTab extends ConsumerStatefulWidget {
  const SavedTab({super.key});

  @override
  ConsumerState<SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends ConsumerState<SavedTab> {
  SavedTypeFilter _currentFilter = SavedTypeFilter.all;

  @override
  Widget build(BuildContext context) {
    final recipesState = ref.watch(savedRecipesProvider);
    final logsState = ref.watch(savedLogsProvider);

    // Initial loading
    final isLoading = (_currentFilter == SavedTypeFilter.all ||
            _currentFilter == SavedTypeFilter.recipes)
        ? (recipesState.isLoading && recipesState.items.isEmpty)
        : (logsState.isLoading && logsState.items.isEmpty);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // CustomScrollView with slivers for unified scrolling
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent * 0.8) {
          // Fetch next page based on current filter
          switch (_currentFilter) {
            case SavedTypeFilter.all:
              // All filter shows limited items, no pagination needed
              break;
            case SavedTypeFilter.recipes:
              ref.read(savedRecipesProvider.notifier).fetchNextPage();
              break;
            case SavedTypeFilter.logs:
              ref.read(savedLogsProvider.notifier).fetchNextPage();
              break;
          }
        }
        return false;
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  buildProfileFilterChip(
                    label: 'profile.filter.all'.tr(),
                    isSelected: _currentFilter == SavedTypeFilter.all,
                    onTap: () =>
                        setState(() => _currentFilter = SavedTypeFilter.all),
                  ),
                  SizedBox(width: 8.w),
                  buildProfileFilterChip(
                    label: 'profile.filter.recipes'.tr(),
                    isSelected: _currentFilter == SavedTypeFilter.recipes,
                    onTap: () => setState(
                        () => _currentFilter = SavedTypeFilter.recipes),
                  ),
                  SizedBox(width: 8.w),
                  buildProfileFilterChip(
                    label: 'profile.filter.logs'.tr(),
                    isSelected: _currentFilter == SavedTypeFilter.logs,
                    onTap: () =>
                        setState(() => _currentFilter = SavedTypeFilter.logs),
                  ),
                ],
              ),
            ),
          ),
          // Content based on filter
          ..._buildContentSlivers(recipesState, logsState),
        ],
      ),
    );
  }

  List<Widget> _buildContentSlivers(
      SavedRecipesState recipesState, SavedLogsState logsState) {
    switch (_currentFilter) {
      case SavedTypeFilter.all:
        return _buildCombinedSlivers(recipesState, logsState);
      case SavedTypeFilter.recipes:
        return _buildRecipesSlivers(recipesState);
      case SavedTypeFilter.logs:
        return _buildLogsSlivers(logsState);
    }
  }

  List<Widget> _buildCombinedSlivers(
      SavedRecipesState recipesState, SavedLogsState logsState) {
    final hasRecipes = recipesState.items.isNotEmpty;
    final hasLogs = logsState.items.isNotEmpty;

    if (!hasRecipes && !hasLogs) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: buildProfileEmptyState(
            icon: Icons.bookmark_border,
            message: 'profile.noSavedYet'.tr(),
            subMessage: 'profile.saveRecipe'.tr(),
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasRecipes) ...[
                Text(
                  'profile.filter.recipes'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                ...recipesState.items
                    .take(3)
                    .map((recipe) => _buildSavedRecipeCard(context, recipe)),
                if (recipesState.items.length > 3)
                  TextButton(
                    onPressed: () =>
                        setState(() => _currentFilter = SavedTypeFilter.recipes),
                    child: Text('+ ${recipesState.items.length - 3} more'),
                  ),
                SizedBox(height: 16.h),
              ],
              if (hasLogs) ...[
                Text(
                  'profile.filter.logs'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                // Grid preview of saved logs
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12.h,
                    crossAxisSpacing: 12.w,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: logsState.items.length > 4 ? 4 : logsState.items.length,
                  itemBuilder: (context, index) {
                    final log = logsState.items[index];
                    return LogPostCard(
                      log: log.toEntity(),
                      showUsername: true,
                      onTap: () => context.push(
                        RouteConstants.logPostDetailPath(log.publicId),
                      ),
                    );
                  },
                ),
                if (logsState.items.length > 4)
                  TextButton(
                    onPressed: () =>
                        setState(() => _currentFilter = SavedTypeFilter.logs),
                    child: Text('+ ${logsState.items.length - 4} more'),
                  ),
              ],
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildRecipesSlivers(SavedRecipesState state) {
    if (state.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: buildProfileEmptyState(
            icon: Icons.bookmark_border,
            message: 'profile.noSavedYet'.tr(),
            subMessage: 'profile.saveRecipe'.tr(),
          ),
        ),
      ];
    }

    return [
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
              return _buildSavedRecipeCard(context, state.items[index]);
            },
            childCount: state.items.length + (state.hasNext ? 1 : 0),
          ),
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: 16.h)),
    ];
  }

  List<Widget> _buildLogsSlivers(SavedLogsState state) {
    if (state.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: buildProfileEmptyState(
            icon: Icons.bookmark_border,
            message: 'profile.noSavedYet'.tr(),
            subMessage: 'profile.saveRecipe'.tr(),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.all(12.r),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 0.85,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= state.items.length) {
                return const Center(child: CircularProgressIndicator());
              }
              final log = state.items[index];
              return LogPostCard(
                log: log.toEntity(),
                showUsername: true,
                onTap: () => context.push(
                  RouteConstants.logPostDetailPath(log.publicId),
                ),
              );
            },
            childCount: state.items.length + (state.hasNext ? 1 : 0),
          ),
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: 16.h)),
    ];
  }

  Widget _buildSavedRecipeCard(BuildContext context, RecipeSummaryDto recipe) {
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
                      width: 80.w,
                      height: 80.h,
                      borderRadius: 0,
                    )
                  : Container(
                      width: 80.w,
                      height: 80.h,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.bookmark,
                          size: 16.sp,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      recipe.foodName,
                      style: TextStyle(
                        fontSize: 12.sp,
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
