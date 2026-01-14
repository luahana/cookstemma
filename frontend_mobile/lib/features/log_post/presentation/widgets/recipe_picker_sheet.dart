import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/providers/recently_viewed_provider.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/enhanced_search_field.dart';
import 'package:pairing_planet2_frontend/data/datasources/search/search_local_data_source.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';

/// Bottom sheet for selecting a recipe before quick logging
class RecipePickerSheet extends ConsumerStatefulWidget {
  final void Function(String recipeId, String recipeTitle) onRecipeSelected;

  const RecipePickerSheet({
    super.key,
    required this.onRecipeSelected,
  });

  /// Show the recipe picker as a modal bottom sheet
  static Future<void> show(
    BuildContext context, {
    required void Function(String recipeId, String recipeTitle) onRecipeSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecipePickerSheet(onRecipeSelected: onRecipeSelected),
    );
  }

  @override
  ConsumerState<RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends ConsumerState<RecipePickerSheet> {
  final LayerLink _layerLink = LayerLink();
  List<RecipeSummary> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _currentQuery = '';

  Future<void> _searchRecipes(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _currentQuery = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
      _errorMessage = null;
      _currentQuery = query;
    });

    try {
      final repository = ref.read(recipeRepositoryProvider);
      final result = await repository.getRecipes(
        cursor: null,
        size: 20,
        query: query.trim(),
      );

      result.fold(
        (failure) {
          setState(() {
            _errorMessage = failure.message;
            _isLoading = false;
          });
        },
        (sliceResponse) {
          setState(() {
            _searchResults = sliceResponse.content;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _currentQuery = '';
    });
  }

  void _selectRecipe(RecipeSummary recipe) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    widget.onRecipeSelected(recipe.publicId, recipe.title);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 8.w, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'recipePicker.title'.tr(),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          // Search bar with enhanced search field
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 12.w),
                    child: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20.sp,
                    ),
                  ),
                  Expanded(
                    child: CompositedTransformTarget(
                      link: _layerLink,
                      child: EnhancedSearchField(
                        hintText: 'recipePicker.searchHint'.tr(),
                        onSearch: _searchRecipes,
                        onClear: _clearSearch,
                        currentQuery: _currentQuery,
                        searchType: SearchType.recipe,
                        autofocus: false,
                        layerLink: _layerLink,
                        overlayOffset: Offset(0, 48.h),
                        overlayWidth: MediaQuery.of(context).size.width - 64.w,
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        textStyle: TextStyle(fontSize: 16.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: _buildContent(),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isSearching && _searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48.sp, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'recipePicker.noResults'.tr(),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (!_isSearching) {
      return _buildRecentlyViewedSection();
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final recipe = _searchResults[index];
        return _RecipeListTile(
          recipe: recipe,
          onTap: () => _selectRecipe(recipe),
        );
      },
    );
  }

  /// Build recently viewed recipes section
  Widget _buildRecentlyViewedSection() {
    final recentRecipes = ref.watch(recentlyViewedRecipesProvider);

    if (recentRecipes.isEmpty) {
      // Show original empty state
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64.sp, color: Colors.grey[300]),
            SizedBox(height: 16.h),
            Text(
              'recipePicker.searchHint'.tr(),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
          child: Text(
            'recipePicker.recentlyViewed'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        // Recent recipes list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: recentRecipes.length,
            itemBuilder: (context, index) {
              final recipe = recentRecipes[index];
              return _RecipeListTile(
                recipe: recipe,
                onTap: () => _selectRecipe(recipe),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Simple recipe list tile for the picker
class _RecipeListTile extends StatelessWidget {
  final RecipeSummary recipe;
  final VoidCallback onTap;

  const _RecipeListTile({
    required this.recipe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  width: 56.w,
                  height: 56.w,
                  color: Colors.grey[200],
                  child: recipe.thumbnailUrl != null
                      ? Image.network(
                          recipe.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.restaurant,
                            color: Colors.grey[400],
                          ),
                        )
                      : Icon(
                          Icons.restaurant,
                          color: Colors.grey[400],
                        ),
                ),
              ),
              SizedBox(width: 12.w),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      recipe.foodName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
