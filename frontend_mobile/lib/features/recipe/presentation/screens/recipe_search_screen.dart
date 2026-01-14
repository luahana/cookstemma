import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/empty_states/search_empty_state.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/enhanced_search_field.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/highlighted_text.dart';
import 'package:pairing_planet2_frontend/core/widgets/skeletons/skeleton_loader.dart';
import 'package:pairing_planet2_frontend/data/datasources/search/search_local_data_source.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/search_results_provider.dart';

/// Unified search screen supporting recipes and log posts with sorting options.
/// Used by View More buttons throughout the app.
class RecipeSearchScreen extends ConsumerStatefulWidget {
  /// Optional initial query to pre-fill and auto-search.
  /// Used when navigating from hashtag tap.
  final String? initialQuery;

  /// Sort option: recent (default), mostForked, trending
  final String? sort;

  /// Content type: recipes (default), logPosts, all
  final String? contentType;

  /// Filter log posts by specific recipe (for recipe detail View More)
  final String? recipeId;

  const RecipeSearchScreen({
    super.key,
    this.initialQuery,
    this.sort,
    this.contentType,
    this.recipeId,
  });

  @override
  ConsumerState<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends ConsumerState<RecipeSearchScreen> {
  final ScrollController _scrollController = ScrollController();
  final LayerLink _layerLink = LayerLink();

  String _currentQuery = '';
  bool _hasSearched = false;

  /// Get provider params based on widget configuration.
  SearchParams get _searchParams => SearchParams(
        sort: widget.sort,
        contentType: widget.contentType,
        recipeId: widget.recipeId,
      );

  /// Whether this is a "View More" mode (has sort/contentType but no initial query).
  bool get _isViewMoreMode =>
      (widget.sort != null || widget.contentType != null) &&
      (widget.initialQuery == null || widget.initialQuery!.isEmpty);

  /// Get context-aware title based on sort/contentType.
  String get _screenTitle {
    // If user has typed a query, show "Search Results"
    if (_hasSearched && _currentQuery.isNotEmpty) {
      return 'search.results'.tr();
    }

    // View More mode titles
    if (widget.sort == 'mostForked') {
      return 'search.mostEvolved'.tr();
    }
    if (widget.sort == 'recent') {
      return 'search.freshUploads'.tr();
    }
    if (widget.contentType == 'logPosts') {
      return 'search.cookingLogs'.tr();
    }

    return 'search.title'.tr();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Auto-search if initial query provided (e.g., from hashtag tap)
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onSearch(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(searchResultsProvider(_searchParams).notifier).fetchNextPage();
    }
  }

  void _onSearch(String query) {
    if (query.trim().isNotEmpty) {
      setState(() {
        _hasSearched = true;
        _currentQuery = query;
      });
      ref.read(searchResultsProvider(_searchParams).notifier).search(query.trim());
    }
  }

  void _onTextChanged(String query) {
    setState(() {
      _currentQuery = query;
    });
  }

  void _clearSearch() {
    setState(() {
      _currentQuery = '';
      _hasSearched = false;
    });
    ref.read(searchResultsProvider(_searchParams).notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider(_searchParams));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(resultsAsync),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    // View More mode: show title instead of search field
    if (_isViewMoreMode && !_hasSearched) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _screenTitle,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // Search icon to enable search mode
          IconButton(
            icon: Icon(Icons.search, color: AppColors.textPrimary, size: 24.sp),
            onPressed: () {
              setState(() {
                _hasSearched = true;
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: Colors.grey[200], height: 1.h),
        ),
      );
    }

    // Search mode: show search field
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: Hero(
        tag: 'search-hero',
        child: Material(
          color: Colors.transparent,
          child: CompositedTransformTarget(
            link: _layerLink,
            child: EnhancedSearchField(
              hintText: 'search.placeholder'.tr(),
              onSearch: _onSearch,
              onClear: _clearSearch,
              currentQuery: _currentQuery,
              searchType: SearchType.recipe,
              autofocus: !_isViewMoreMode,
              layerLink: _layerLink,
              overlayOffset: const Offset(0, kToolbarHeight),
              overlayWidth: MediaQuery.of(context).size.width - 100.w,
              onTextChanged: _onTextChanged,
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(color: Colors.grey[200], height: 1.h),
      ),
    );
  }

  Widget _buildBody(AsyncValue<SearchResultsState> resultsAsync) {
    // View More mode: always show results (auto-fetched by provider)
    if (_isViewMoreMode) {
      return _buildSearchResults(resultsAsync);
    }

    // Search mode: show empty content until user searches
    if (!_hasSearched || _currentQuery.isEmpty) {
      return _buildEmptyContent();
    }

    return _buildSearchResults(resultsAsync);
  }

  /// Empty content shown before searching.
  Widget _buildEmptyContent() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64.sp,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16.h),
            Text(
              'search.startTyping'.tr(),
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Whether currently showing log posts.
  bool get _isLogPostMode => widget.contentType == 'logPosts';

  /// Search results view.
  Widget _buildSearchResults(AsyncValue<SearchResultsState> resultsAsync) {
    return resultsAsync.when(
      data: (state) {
        final items = state.items;
        final hasNext = state.hasNext;

        if (items.isEmpty) {
          // In View More mode with no results, show appropriate message
          if (_isViewMoreMode && !_hasSearched) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isLogPostMode ? Icons.history_edu : Icons.restaurant_menu,
                      size: 64.sp,
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      _isLogPostMode
                          ? 'logPost.noLogsYet'.tr()
                          : 'recipe.noRecipesYet'.tr(),
                      style: TextStyle(fontSize: 16.sp, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return SearchEmptyState(
            query: _currentQuery,
            entityName: _isLogPostMode ? 'logPost.title'.tr() : 'recipe.title'.tr(),
            onClearSearch: _clearSearch,
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(16.r),
          itemCount: hasNext ? items.length + 1 : items.length,
          itemBuilder: (context, index) {
            if (hasNext && index == items.length) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final item = items[index];
            return switch (item) {
              RecipeSearchItem(:final recipe) => _buildSearchResultCard(
                  recipe,
                  key: ValueKey(recipe.publicId),
                ),
              LogPostSearchItem(:final logPost) => _buildLogPostCard(
                  logPost,
                  key: ValueKey(logPost.id),
                ),
            };
          },
        );
      },
      loading: () => const RecipeListSkeleton(),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: Colors.red[300]),
            SizedBox(height: 16.h),
            Text(
              'common.error'.tr(),
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () => ref.invalidate(searchResultsProvider(_searchParams)),
              child: Text('common.tryAgain'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(RecipeSummary recipe, {Key? key}) {
    return Semantics(
      key: key,
      button: true,
      label: recipe.title,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push(RouteConstants.recipeDetailPath(recipe.publicId));
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: recipe.thumbnailUrl != null
                    ? AppCachedImage(
                        imageUrl: recipe.thumbnailUrl,
                        width: 70.w,
                        height: 70.w,
                        borderRadius: 0,
                      )
                    : Container(
                        width: 70.w,
                        height: 70.w,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.restaurant_menu,
                          color: Colors.grey[400],
                          size: 24.sp,
                        ),
                      ),
              ),
              SizedBox(width: 12.w),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food name
                    Text(
                      recipe.foodName,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    // Title with highlight
                    HighlightedText(
                      text: recipe.title,
                      query: _currentQuery,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    // Creator
                    Text(
                      '@${recipe.creatorName}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogPostCard(LogPostSummary logPost, {Key? key}) {
    return Semantics(
      key: key,
      button: true,
      label: logPost.title,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push(RouteConstants.logPostDetailPath(logPost.id));
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail with outcome overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: logPost.thumbnailUrl != null
                        ? AppCachedImage(
                            imageUrl: logPost.thumbnailUrl,
                            width: 70.w,
                            height: 70.w,
                            borderRadius: 0,
                          )
                        : Container(
                            width: 70.w,
                            height: 70.w,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.history_edu,
                              color: Colors.grey[400],
                              size: 24.sp,
                            ),
                          ),
                  ),
                  // Outcome emoji overlay
                  if (logPost.outcome != null)
                    Positioned(
                      right: 4.w,
                      bottom: 4.h,
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          _getOutcomeEmoji(logPost.outcome!),
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 12.w),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food name
                    if (logPost.foodName != null)
                      Text(
                        logPost.foodName!,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    SizedBox(height: 2.h),
                    // Title with highlight
                    HighlightedText(
                      text: logPost.title,
                      query: _currentQuery,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    // Creator
                    if (logPost.creatorName != null)
                      Text(
                        '@${logPost.creatorName}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getOutcomeEmoji(String outcome) {
    return switch (outcome.toUpperCase()) {
      'SUCCESS' => '🎉',
      'PARTIAL' => '🤔',
      'FAILED' => '😅',
      _ => '📝',
    };
  }
}
