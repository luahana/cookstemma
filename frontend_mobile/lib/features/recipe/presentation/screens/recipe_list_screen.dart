import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/empty_states/illustrated_empty_state.dart';
import 'package:pairing_planet2_frontend/core/widgets/empty_states/search_empty_state.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/enhanced_search_app_bar.dart';
import 'package:pairing_planet2_frontend/core/widgets/skeleton/skeleton_loader.dart';
import 'package:pairing_planet2_frontend/core/widgets/transitions/animated_view_switcher.dart';
import 'package:pairing_planet2_frontend/data/datasources/search/search_local_data_source.dart';
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

  @override
  Widget build(BuildContext context) {
    // 💡 이제 recipesAsync의 데이터는 RecipeListState 객체입니다.
    final recipesAsync = ref.watch(recipeListProvider);
    final viewMode = ref.watch(browseViewModeProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: EnhancedSearchAppBar(
        title: 'recipe.browse'.tr(),
        hintText: 'recipe.searchHint'.tr(),
        currentQuery: recipesAsync.valueOrNull?.searchQuery,
        searchType: SearchType.recipe,
        onSearch: (query) {
          ref.read(recipeListProvider.notifier).search(query);
        },
        onClear: () {
          ref.read(recipeListProvider.notifier).clearSearch();
        },
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: CompactViewModeToggle(),
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
      case BrowseViewMode.star:
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
      case BrowseViewMode.star:
        // Star view shows original recipes with prominent star badges
        // Filter to only show originals when in star view mode
        final originals = recipes.where((r) => !r.isVariant).toList();
        if (originals.isEmpty) {
          return _buildStarEmptyState();
        }
        return _buildStarGridView(originals, hasNext, state);
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

  Widget _buildStarEmptyState() {
    return IllustratedEmptyState(
      icon: Icons.auto_awesome_outlined,
      title: 'star.noVariants'.tr(),
      subtitle: 'star.createFirst'.tr(),
      iconColor: Colors.purple[300],
    );
  }

  Widget _buildStarGridView(List<RecipeSummary> originals, bool hasNext, RecipeListState state) {
    return Column(
      children: [
        // Star view info banner
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          color: AppColors.primary.withValues(alpha: 0.1),
          child: Row(
            children: [
              Text('⭐', style: TextStyle(fontSize: 16.sp)),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'star.tapToSelect'.tr(),
                  style: TextStyle(fontSize: 13.sp, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        // Cache indicator
        if (state.isFromCache && state.cachedAt != null)
          _buildCacheIndicator(state),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(16.r),
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemCount: hasNext ? originals.length + 1 : originals.length,
            itemBuilder: (context, index) {
              if (hasNext && index == originals.length) {
                return const Center(child: CircularProgressIndicator());
              }
              final recipe = originals[index];
              return _buildStarCard(recipe);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStarCard(RecipeSummary recipe) {
    return Semantics(
      button: true,
      label: 'Recipe family: ${recipe.title} with ${recipe.variantCount} variants',
      hint: 'Double tap to view star graph',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push(RouteConstants.recipeStarPath(recipe.publicId));
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with star badge
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.r),
                      topRight: Radius.circular(12.r),
                    ),
                    child: AppCachedImage(
                      imageUrl: recipe.thumbnailUrl ?? 'https://via.placeholder.com/200',
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 0,
                    ),
                  ),
                  // Star badge overlay
                  Positioned(
                    bottom: 8.h,
                    left: 8.w,
                    right: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('⭐', style: TextStyle(fontSize: 12.sp)),
                          SizedBox(width: 4.w),
                          Text(
                            '${recipe.variantCount}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' · ${recipe.logCount}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(10.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      'star.variants'.tr(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
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
      onLog: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
      onFork: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
      onViewStar: () {
        // For original recipes, use the recipe's own ID
        // For variants, use the root recipe ID if available
        final starRecipeId = recipe.isVariant && recipe.rootPublicId != null
            ? recipe.rootPublicId!
            : recipe.publicId;
        context.push(RouteConstants.recipeStarPath(starRecipeId));
      },
      onViewRoot: recipe.rootPublicId != null
          ? () => context.push(RouteConstants.recipeDetailPath(recipe.rootPublicId!))
          : null,
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
