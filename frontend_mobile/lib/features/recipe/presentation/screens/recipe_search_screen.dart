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
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_list_provider.dart';

/// Dedicated recipe search screen with search history overlay and results.
class RecipeSearchScreen extends ConsumerStatefulWidget {
  /// Optional initial query to pre-fill and auto-search.
  /// Used when navigating from hashtag tap.
  final String? initialQuery;

  const RecipeSearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends ConsumerState<RecipeSearchScreen> {
  final ScrollController _scrollController = ScrollController();
  final LayerLink _layerLink = LayerLink();

  String _currentQuery = '';
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Infinite scroll listener
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
      ref.read(recipeListProvider.notifier).fetchNextPage();
    }
  }

  void _onSearch(String query) {
    if (query.trim().isNotEmpty) {
      setState(() {
        _hasSearched = true;
        _currentQuery = query;
      });
      ref.read(recipeListProvider.notifier).search(query.trim());
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
    ref.read(recipeListProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipeListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildSearchAppBar(),
      body: !_hasSearched || _currentQuery.isEmpty
          ? _buildEmptyContent()
          : _buildSearchResults(recipesAsync),
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
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
              autofocus: true,
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
        child: Container(
          color: Colors.grey[200],
          height: 1.h,
        ),
      ),
    );
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

  /// Search results view.
  Widget _buildSearchResults(AsyncValue<RecipeListState> recipesAsync) {
    return recipesAsync.when(
      data: (state) {
        final recipes = state.items;
        final hasNext = state.hasNext;

        if (recipes.isEmpty) {
          return SearchEmptyState(
            query: _currentQuery,
            entityName: 'recipe.title'.tr(),
            onClearSearch: _clearSearch,
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(16.r),
          itemCount: hasNext ? recipes.length + 1 : recipes.length,
          itemBuilder: (context, index) {
            if (hasNext && index == recipes.length) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final recipe = recipes[index];
            return _buildSearchResultCard(recipe, key: ValueKey(recipe.publicId));
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
              onPressed: () => ref.invalidate(recipeListProvider),
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
}
