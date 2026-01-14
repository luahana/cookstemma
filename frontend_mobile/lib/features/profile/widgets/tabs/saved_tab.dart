import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/widgets/log_post_card.dart';
import 'package:pairing_planet2_frontend/core/widgets/unified_recipe_card.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/widgets/profile_shared.dart';

/// Filter for saved tab (no "all" option)
enum _SavedFilter { recipes, logs }

/// Saved Tab - displays saved recipes and logs
class SavedTab extends ConsumerStatefulWidget {
  const SavedTab({super.key});

  @override
  ConsumerState<SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends ConsumerState<SavedTab> {
  _SavedFilter _currentFilter = _SavedFilter.recipes;

  @override
  Widget build(BuildContext context) {
    final recipesState = ref.watch(savedRecipesProvider);
    final logsState = ref.watch(savedLogsProvider);

    // Initial loading based on current filter
    final isLoading = _currentFilter == _SavedFilter.recipes
        ? (recipesState.isLoading && recipesState.items.isEmpty)
        : (logsState.isLoading && logsState.items.isEmpty);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent * 0.8) {
          // Fetch next page based on current filter
          if (_currentFilter == _SavedFilter.recipes) {
            ref.read(savedRecipesProvider.notifier).fetchNextPage();
          } else {
            ref.read(savedLogsProvider.notifier).fetchNextPage();
          }
        }
        return false;
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Filter chips (Recipes and Logs only - no All)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  buildProfileFilterChip(
                    label: 'profile.filter.recipes'.tr(),
                    isSelected: _currentFilter == _SavedFilter.recipes,
                    onTap: () =>
                        setState(() => _currentFilter = _SavedFilter.recipes),
                  ),
                  SizedBox(width: 8.w),
                  buildProfileFilterChip(
                    label: 'profile.filter.logs'.tr(),
                    isSelected: _currentFilter == _SavedFilter.logs,
                    onTap: () =>
                        setState(() => _currentFilter = _SavedFilter.logs),
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
    if (_currentFilter == _SavedFilter.recipes) {
      return _buildRecipesSlivers(recipesState);
    } else {
      return _buildLogsSlivers(logsState);
    }
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
      // Horizontal recipe cards (single column list)
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        sliver: SliverList.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final recipe = state.items[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: UnifiedRecipeCard(
                recipe: recipe.toEntity(),
                isVertical: false, // Horizontal layout
              ),
            );
          },
        ),
      ),
      // Loading indicator
      if (state.hasNext)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: const Center(child: CircularProgressIndicator()),
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
      // Log cards in 2-column grid
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 0.75,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final log = state.items[index];
              return LogPostCard(
                log: log.toEntity(),
                showUsername: true,
                onTap: () => context.push(
                  RouteConstants.logPostDetailPath(log.publicId),
                ),
              );
            },
            childCount: state.items.length,
          ),
        ),
      ),
      // Loading indicator
      if (state.hasNext)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      SliverToBoxAdapter(child: SizedBox(height: 16.h)),
    ];
  }
}
