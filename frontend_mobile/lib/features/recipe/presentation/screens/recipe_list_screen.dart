import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
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
import 'package:pairing_planet2_frontend/core/widgets/skeleton/skeleton_loader.dart';
import 'package:pairing_planet2_frontend/core/widgets/transitions/animated_view_switcher.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/bento_grid_view.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/enhanced_recipe_card.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/view_mode_toggle.dart';
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

  Widget _buildFilterTabs() {
    final filterState = ref.watch(browseFilterProvider);
    final typeFilter = filterState.typeFilter;

    return Padding(
      padding: EdgeInsets.only(left: 16.w),
      child: Row(
        children: [
          _FilterTab(
            label: 'filter.all'.tr(),
            isSelected: typeFilter == RecipeTypeFilter.all,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(browseFilterProvider.notifier).setTypeFilter(RecipeTypeFilter.all);
            },
          ),
          SizedBox(width: 20.w),
          _FilterTab(
            label: 'filter.originals'.tr(),
            isSelected: typeFilter == RecipeTypeFilter.originals,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(browseFilterProvider.notifier).setTypeFilter(RecipeTypeFilter.originals);
            },
          ),
          SizedBox(width: 20.w),
          _FilterTab(
            label: 'filter.variants'.tr(),
            isSelected: typeFilter == RecipeTypeFilter.variants,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(browseFilterProvider.notifier).setTypeFilter(RecipeTypeFilter.variants);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    final filterState = ref.watch(browseFilterProvider);
    final currentSort = filterState.sortOption;
    final isActive = currentSort != RecipeSortOption.recent;

    return PopupMenuButton<RecipeSortOption>(
      icon: Icon(
        Icons.sort,
        color: isActive ? AppColors.primary : Colors.black,
      ),
      tooltip: 'filter.sort'.tr(),
      onSelected: (option) {
        HapticFeedback.selectionClick();
        ref.read(browseFilterProvider.notifier).setSortOption(option);
      },
      offset: Offset(0, 40.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      itemBuilder: (context) => [
        _buildSortMenuItem(RecipeSortOption.recent, 'filter.sortRecent'.tr(), Icons.access_time, currentSort),
        _buildSortMenuItem(RecipeSortOption.trending, 'filter.sortTrending'.tr(), Icons.trending_up, currentSort),
        _buildSortMenuItem(RecipeSortOption.mostForked, 'filter.sortMostForked'.tr(), Icons.call_split, currentSort),
      ],
    );
  }

  PopupMenuItem<RecipeSortOption> _buildSortMenuItem(
    RecipeSortOption option,
    String label,
    IconData icon,
    RecipeSortOption currentSort,
  ) {
    final isSelected = currentSort == option;
    return PopupMenuItem<RecipeSortOption>(
      value: option,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18.sp,
            color: isSelected ? AppColors.primary : Colors.grey[600],
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppColors.primary : Colors.grey[800],
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check, size: 18.sp, color: AppColors.primary),
          ],
        ],
      ),
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
    final viewMode = ref.watch(browseViewModeProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollViewPlus(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // SliverAppBar with filter tabs
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: innerBoxIsScrolled ? 1 : 0,
            titleSpacing: 0,
            title: _buildFilterTabs(),
            actions: [
              _buildSortButton(),
              const CompactViewModeToggle(),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => context.push(RouteConstants.search),
              ),
            ],
          ),
          // Instagram-style pull-to-refresh
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(recipeListProvider);
              return ref.read(recipeListProvider.future);
            },
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
              return recipesAsync.when(
                data: (state) => _buildContentBody(state, viewMode),
                loading: () => _buildSkeletonLoading(viewMode),
                error: (err, stack) => IllustratedEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'common.error'.tr(),
                  subtitle: err.toString(),
                  actionLabel: 'common.tryAgain'.tr(),
                  onAction: () => ref.invalidate(recipeListProvider),
                  iconColor: Colors.red[300],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContentBody(RecipeListState state, BrowseViewMode viewMode) {
    final recipes = state.items;
    final hasNext = state.hasNext;

    // Empty state
    if (recipes.isEmpty) {
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
      return Column(
        children: [
          if (state.isFromCache && state.cachedAt != null)
            _buildCacheIndicator(state),
          Expanded(
            child: IllustratedEmptyState(
              icon: Icons.restaurant_menu_outlined,
              title: 'recipe.noRecipesYet'.tr(),
              subtitle: 'recipe.pullToRefresh'.tr(),
              iconColor: Colors.orange[300],
            ),
          ),
        ],
      );
    }

    // Data available - build content based on view mode
    return Column(
      children: [
        if (state.isFromCache && state.cachedAt != null)
          _buildCacheIndicator(state),
        Expanded(
          child: AnimatedViewSwitcher(
            key: ValueKey(viewMode),
            child: KeyedSubtree(
              key: ValueKey('content_$viewMode'),
              child: _buildContentView(recipes, hasNext, state, viewMode),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoading(BrowseViewMode viewMode) {
    switch (viewMode) {
      case BrowseViewMode.grid:
        return const RecipeGridSkeleton();
      case BrowseViewMode.list:
        return const RecipeListSkeleton();
    }
  }

  Widget _buildContentView(
    List<RecipeSummary> recipes,
    bool hasNext,
    RecipeListState state,
    BrowseViewMode viewMode,
  ) {
    switch (viewMode) {
      case BrowseViewMode.grid:
        return _buildGridView(recipes, hasNext, state);
      case BrowseViewMode.list:
        return _buildListView(recipes, hasNext, state);
    }
  }

  Widget _buildListView(List<RecipeSummary> recipes, bool hasNext, RecipeListState state) {
    return ListView.builder(
      padding: EdgeInsets.all(16.r),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: hasNext ? recipes.length + 1 : recipes.length,
      itemBuilder: (context, index) {
        // 다음 페이지가 있고, 마지막 인덱스일 때 로딩바 표시
        if (hasNext && index == recipes.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 32.h),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final recipe = recipes[index];
        final card = _buildRecipeCard(context, recipe, state.searchQuery);

        // 더 이상 데이터가 없을 때 하단에 안내 문구 표시
        if (!hasNext && index == recipes.length - 1) {
          return Column(
            children: [
              card,
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Text(
                  'recipe.allLoaded'.tr(),
                  style: TextStyle(color: Colors.grey, fontSize: 13.sp),
                ),
              ),
            ],
          );
        }

        return card;
      },
    );
  }

  Widget _buildGridView(List<RecipeSummary> recipes, bool hasNext, RecipeListState state) {
    return BentoGridView(
      recipes: recipes,
      hasNext: hasNext,
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

  Widget _buildRecipeCard(BuildContext context, RecipeSummary recipe, String? searchQuery) {
    return EnhancedRecipeCard(
      recipe: recipe,
      searchQuery: searchQuery,
      // TODO: Add ingredientPreviews when backend provides this data
      ingredientPreviews: null,
      // TODO: Add diffSummary when backend provides this data
      diffSummary: null,
      onTap: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
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
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppColors.primary : Colors.grey[600],
            ),
          ),
          SizedBox(height: 4.h),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2.h,
            width: isSelected ? 24.w : 0,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
        ],
      ),
    );
  }
}
