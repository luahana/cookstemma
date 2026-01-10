import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/providers/scroll_to_top_provider.dart';
import 'package:pairing_planet2_frontend/core/widgets/empty_states/illustrated_empty_state.dart';
import 'package:pairing_planet2_frontend/core/widgets/empty_states/search_empty_state.dart';
import 'package:pairing_planet2_frontend/core/widgets/skeleton/skeleton_loader.dart';
import 'package:pairing_planet2_frontend/core/widgets/transitions/animated_view_switcher.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/bento_grid_view.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/browse_filter_bar.dart';
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
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        // 💡 다음 페이지 가져오기 호출
        ref.read(recipeListProvider.notifier).fetchNextPage();
      }
    });
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'recipe.browse'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: CompactViewModeToggle(),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(RouteConstants.search),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          const BrowseFilterBar(),
          // Main content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(recipeListProvider);
                return ref.read(recipeListProvider.future);
              },
              child: recipesAsync.when(
                data: (state) {
                  final recipes = state.items;
                  final hasNext = state.hasNext;

                  // 데이터가 없을 때도 스크롤 가능하게 ListView를 반환
                  if (recipes.isEmpty) {
                    // 검색 결과가 없는 경우
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
                    // 일반 빈 상태
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          // Show cache indicator even when empty
                          if (state.isFromCache && state.cachedAt != null)
                            _buildCacheIndicator(state),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                          IllustratedEmptyState(
                            icon: Icons.restaurant_menu_outlined,
                            title: 'recipe.noRecipesYet'.tr(),
                            subtitle: 'recipe.pullToRefresh'.tr(),
                            iconColor: Colors.orange[300],
                          ),
                        ],
                      ),
                    );
                  }

                  // Build content based on view mode with animated transitions
                  return AnimatedViewSwitcher(
                    key: ValueKey(viewMode),
                    child: KeyedSubtree(
                      key: ValueKey('content_$viewMode'),
                      child: _buildContentView(recipes, hasNext, state, viewMode),
                    ),
                  );
                },
                loading: () => _buildSkeletonLoading(viewMode),
                error: (err, stack) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: IllustratedEmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'common.error'.tr(),
                      subtitle: err.toString(),
                      actionLabel: 'common.tryAgain'.tr(),
                      onAction: () => ref.invalidate(recipeListProvider),
                      iconColor: Colors.red[300],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
    return Column(
      children: [
        // Cache indicator at top when showing cached data
        if (state.isFromCache && state.cachedAt != null)
          _buildCacheIndicator(state),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
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
          ),
        ),
      ],
    );
  }

  Widget _buildGridView(List<RecipeSummary> recipes, bool hasNext, RecipeListState state) {
    return Column(
      children: [
        // Cache indicator at top when showing cached data
        if (state.isFromCache && state.cachedAt != null)
          _buildCacheIndicator(state),
        Expanded(
          child: BentoGridView(
            recipes: recipes,
            hasNext: hasNext,
            scrollController: _scrollController,
          ),
        ),
      ],
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
