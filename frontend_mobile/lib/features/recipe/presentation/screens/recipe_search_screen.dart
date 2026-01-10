import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/providers/search_history_provider.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/empty_states/search_empty_state.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/highlighted_text.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/recent_search_tile.dart';
import 'package:pairing_planet2_frontend/core/widgets/skeleton/skeleton_loader.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/cooking_style_chips.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/trending_searches_section.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_list_provider.dart';

/// Dedicated recipe search screen with recent searches, trending, and results.
class RecipeSearchScreen extends ConsumerStatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  ConsumerState<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends ConsumerState<RecipeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  String _currentQuery = '';
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus search field on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    // Infinite scroll listener
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(recipeListProvider.notifier).fetchNextPage();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _currentQuery = query;
    });

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().isNotEmpty) {
        _hasSearched = true;
        ref.read(recipeListProvider.notifier).search(query.trim());
        // Add to search history
        ref.read(recipeSearchHistoryProvider.notifier).addSearch(query.trim());
      }
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      _hasSearched = true;
      ref.read(recipeListProvider.notifier).search(query.trim());
      ref.read(recipeSearchHistoryProvider.notifier).addSearch(query.trim());
      _focusNode.unfocus();
    }
  }

  void _onRecentSearchTap(String term) {
    HapticFeedback.selectionClick();
    _searchController.text = term;
    _currentQuery = term;
    _hasSearched = true;
    ref.read(recipeListProvider.notifier).search(term);
    ref.read(recipeSearchHistoryProvider.notifier).addSearch(term);
    _focusNode.unfocus();
  }

  void _onCookingStyleTap(String style) {
    HapticFeedback.selectionClick();
    _searchController.text = style;
    _currentQuery = style;
    _hasSearched = true;
    ref.read(recipeListProvider.notifier).search(style);
    ref.read(recipeSearchHistoryProvider.notifier).addSearch(style);
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentQuery = '';
      _hasSearched = false;
    });
    ref.read(recipeListProvider.notifier).clearSearch();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final searchHistory = ref.watch(recipeSearchHistoryProvider);
    final recipesAsync = ref.watch(recipeListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildSearchAppBar(),
      body: _currentQuery.isEmpty || !_hasSearched
          ? _buildDiscoveryContent(searchHistory)
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
      title: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        onSubmitted: _onSearchSubmitted,
        style: TextStyle(fontSize: 16.sp),
        decoration: InputDecoration(
          hintText: 'search.placeholder'.tr(),
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16.sp,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        ),
      ),
      actions: [
        if (_currentQuery.isNotEmpty)
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[600], size: 22.sp),
            onPressed: _clearSearch,
          ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(
          color: Colors.grey[200],
          height: 1.h,
        ),
      ),
    );
  }

  /// Discovery content shown when search is empty.
  Widget _buildDiscoveryContent(List<String> searchHistory) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (searchHistory.isNotEmpty) ...[
            _buildRecentSearchesSection(searchHistory),
            SizedBox(height: 24.h),
          ],

          // Trending Searches
          const TrendingSearchesSection(),
          SizedBox(height: 24.h),

          // Cooking Style Chips
          CookingStyleChips(
            onStyleSelected: _onCookingStyleTap,
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildRecentSearchesSection(List<String> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'search.recentSearches'.tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(recipeSearchHistoryProvider.notifier).clearAll();
                },
                child: Text(
                  'search.clearAll'.tr(),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        // Recent search items
        ...history.take(5).map((term) => RecentSearchTile(
          term: term,
          query: _currentQuery.isNotEmpty ? _currentQuery : null,
          onTap: () => _onRecentSearchTap(term),
          onRemove: () {
            HapticFeedback.lightImpact();
            ref.read(recipeSearchHistoryProvider.notifier).removeSearch(term);
          },
        )),
      ],
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
            return _buildSearchResultCard(recipe);
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

  Widget _buildSearchResultCard(RecipeSummary recipe) {
    return Semantics(
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
                child: AppCachedImage(
                  imageUrl: recipe.thumbnailUrl,
                  width: 70.w,
                  height: 70.w,
                  borderRadius: 0,
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
