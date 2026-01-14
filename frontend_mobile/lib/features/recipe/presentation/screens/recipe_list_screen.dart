import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/providers/scroll_to_top_provider.dart';
import 'package:flutter/services.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/empty_states/illustrated_empty_state.dart';
import 'package:pairing_planet2_frontend/core/widgets/empty_states/search_empty_state.dart';
import 'package:pairing_planet2_frontend/core/widgets/skeletons/skeleton_loader.dart';
import 'package:pairing_planet2_frontend/core/widgets/unified_recipe_card.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/hero_search_icon.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_logo.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/browse_filter_provider.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_list_provider.dart';

class RecipeListScreen extends ConsumerStatefulWidget {
  const RecipeListScreen({super.key});

  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Note: Pagination is now handled via NotificationListener in the body
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildFilterRow() {
    // Use Consumer to isolate rebuilds and prevent setState during build errors
    return Consumer(
      builder: (context, ref, _) {
        final filterState = ref.watch(browseFilterProvider);
        final typeFilter = filterState.typeFilter;

        return Container(
          color: AppColors.surface,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          child: Row(
            children: [
              _FilterTab(
                label: 'filter.all'.tr(),
                isSelected: typeFilter == RecipeTypeFilter.all,
                onTap: () {
                  if (typeFilter == RecipeTypeFilter.all) return;
                  HapticFeedback.selectionClick();
                  ref.read(browseFilterProvider.notifier).setTypeFilter(RecipeTypeFilter.all);
                },
              ),
              SizedBox(width: 20.w),
              _FilterTab(
                label: 'filter.originals'.tr(),
                isSelected: typeFilter == RecipeTypeFilter.originals,
                onTap: () {
                  if (typeFilter == RecipeTypeFilter.originals) return;
                  HapticFeedback.selectionClick();
                  ref.read(browseFilterProvider.notifier).setTypeFilter(RecipeTypeFilter.originals);
                },
              ),
              SizedBox(width: 20.w),
              _FilterTab(
                label: 'filter.variants'.tr(),
                isSelected: typeFilter == RecipeTypeFilter.variants,
                onTap: () {
                  if (typeFilter == RecipeTypeFilter.variants) return;
                  HapticFeedback.selectionClick();
                  ref.read(browseFilterProvider.notifier).setTypeFilter(RecipeTypeFilter.variants);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to scroll-to-top events for tab index 1 (Recipes)
    ref.listen<int>(scrollToTopProvider(1), (previous, current) {
      if (previous != null && current != previous) {
        _scrollToTop();
      }
    });
    // 💡 이제 recipesAsync의 데이터는 RecipeListState 객체입니다.
    final recipesAsync = ref.watch(recipeListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(recipeListProvider.notifier).refresh();
        },
        child: NestedScrollViewPlus(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // SliverAppBar with logo, search, and pinned filter row
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: AppColors.surface,
              foregroundColor: Colors.black,
              scrolledUnderElevation: innerBoxIsScrolled ? 1 : 0,
              centerTitle: false,
              title: const AppLogo(),
              actions: [
                HeroSearchIcon(
                  onTap: () => context.push(RouteConstants.search),
                  heroTag: 'search-hero',
                ),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(32.h),
                child: _buildFilterRow(),
              ),
            ),
          ],
          body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              final metrics = notification.metrics;
              if (metrics.pixels >= metrics.maxScrollExtent - 300) {
                ref.read(recipeListProvider.notifier).fetchNextPage();
              }
            }
            return false;
          },
          child: Builder(
            builder: (context) {
              // Match LogPostListScreen pattern - return different widget types
              return recipesAsync.when(
                data: (state) => _buildContentBody(state),
                loading: () => const RecipeListSkeleton(),
                error: (error, stack) => _buildErrorBody(error),
              );
            },
          ),
          ),
        ),
      ),
    );
  }

  /// Build content body - matches LogPostListScreen pattern
  /// Returns Column for empty states, CustomScrollView for content
  Widget _buildContentBody(RecipeListState state) {
    final recipes = state.items;

    // Empty state - return Column (non-scrollable)
    if (recipes.isEmpty) {
      return Column(
        children: [
          if (state.isFromCache && state.cachedAt != null)
            _buildCacheIndicator(state),
          Expanded(child: _buildEmptyStateContent(state)),
        ],
      );
    }

    // Data available - return CustomScrollView with proper slivers
    return CustomScrollView(
      slivers: [
        // Cache indicator
        if (state.isFromCache && state.cachedAt != null)
          SliverToBoxAdapter(child: _buildCacheIndicator(state)),

        // Single column list view
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
          sliver: SliverList.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: UnifiedRecipeCard(
                recipe: recipes[index],
                isVertical: true,
              ),
            ),
          ),
        ),

        // Loading indicator or end message
        if (state.hasNext)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: const Center(child: CircularProgressIndicator()),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text(
                  'recipe.allLoaded'.tr(),
                  style: TextStyle(color: Colors.grey, fontSize: 13.sp),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build empty state content based on current filters/search
  Widget _buildEmptyStateContent(RecipeListState state) {
    // Search results empty
    if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
      return SearchEmptyState(
        query: state.searchQuery!,
        entityName: 'recipe.title'.tr(),
        onClearSearch: () {
          ref.read(recipeListProvider.notifier).clearSearch();
        },
      );
    }
    // Filter results empty
    if (state.filterState?.hasActiveFilters == true) {
      return _buildFilterEmptyState();
    }
    // General empty state
    return IllustratedEmptyState(
      icon: Icons.restaurant_menu_outlined,
      title: 'recipe.noRecipesYet'.tr(),
      subtitle: 'recipe.pullToRefresh'.tr(),
      iconColor: Colors.orange[300],
    );
  }

  /// Build error body - non-scrollable
  Widget _buildErrorBody(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48.sp, color: Colors.red[300]),
          SizedBox(height: 16.h),
          Text(
            'common.error'.tr(),
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 8.h),
          Text(
            error.toString(),
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => ref.invalidate(recipeListProvider),
            child: Text('common.tryAgain'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterEmptyState() {
    return IllustratedEmptyState(
      icon: Icons.filter_alt_off_outlined,
      title: 'filter.noResults'.tr(),
      subtitle: 'filter.clearAll'.tr(),
      actionLabel: 'filter.clearAll'.tr(),
      onAction: () {
        ref.read(browseFilterProvider.notifier).clearAllFilters();
      },
      iconColor: Colors.blue[300],
    );
  }

  /// Cache indicator showing when data is from cache.
  Widget _buildCacheIndicator(RecipeListState state) {
    final cachedAt = state.cachedAt;
    if (cachedAt == null) return const SizedBox.shrink();

    final diff = DateTime.now().difference(cachedAt);
    String timeText;
    if (diff.inMinutes < 1) {
      timeText = 'common.justNow'.tr();
    } else if (diff.inMinutes < 60) {
      timeText = 'common.minutesAgo'.tr(namedArgs: {'count': diff.inMinutes.toString()});
    } else {
      timeText = 'common.hoursAgo'.tr(namedArgs: {'count': diff.inHours.toString()});
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: Colors.orange[50],
      child: Row(
        children: [
          Icon(Icons.access_time, size: 14.sp, color: Colors.orange[700]),
          SizedBox(width: 6.w),
          Text(
            'recipe.offlineData'.tr(namedArgs: {'time': timeText}),
            style: TextStyle(fontSize: 12.sp, color: Colors.orange[700]),
          ),
        ],
      ),
    );
  }
}

/// Filter tab widget with underline indicator
class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : Colors.grey[500],
            ),
          ),
          SizedBox(height: 6.h),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3.h,
            width: isSelected ? 24.w : 0,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(1.5.r),
            ),
          ),
        ],
      ),
    );
  }
}
