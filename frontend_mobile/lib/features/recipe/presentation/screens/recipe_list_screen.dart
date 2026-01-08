import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/empty_states/search_empty_state.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/enhanced_search_app_bar.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/highlighted_text.dart';
import 'package:pairing_planet2_frontend/data/datasources/search/search_local_data_source.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
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
      ),
      body: RefreshIndicator(
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
              // 일반 빈 상태
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Show cache indicator even when empty
                  if (state.isFromCache && state.cachedAt != null)
                    _buildCacheIndicator(state),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'recipe.noRecipesYet'.tr(),
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'recipe.pullToRefresh'.tr(),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                // Cache indicator at top when showing cached data
                if (state.isFromCache && state.cachedAt != null)
                  _buildCacheIndicator(state),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: hasNext ? recipes.length + 1 : recipes.length,
                    itemBuilder: (context, index) {
                      // 다음 페이지가 있고, 마지막 인덱스일 때 로딩바 표시
                      if (hasNext && index == recipes.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
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
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'recipe.allLoaded'.tr(),
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
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
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('common.errorWithMessage'.tr(namedArgs: {'message': err.toString()})),
                    TextButton(
                      onPressed: () => ref.invalidate(recipeListProvider),
                      child: Text('common.tryAgain'.tr()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, RecipeSummary recipe, String? searchQuery) {
    final isVariant = recipe.rootPublicId != null;
    return GestureDetector(
      onTap: () =>
          context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppCachedImage(
                  imageUrl:
                      recipe.thumbnailUrl ??
                      'https://via.placeholder.com/400x200',
                  width: double.infinity,
                  height: 180,
                  borderRadius: 16,
                ),
                Positioned(top: 12, left: 12, child: _buildBadge(isVariant)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HighlightedText(
                    text: recipe.foodName,
                    query: searchQuery,
                    style: TextStyle(
                      color: Colors.indigo[900],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  HighlightedText(
                    text: recipe.title,
                    query: searchQuery,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  HighlightedText(
                    text: recipe.description,
                    query: searchQuery,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  // Activity counts row
                  _buildActivityRow(recipe),
                  const SizedBox(height: 8),
                  // Creator and root link row
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recipe.creatorName,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const Spacer(),
                      // Show root link for variants
                      if (recipe.isVariant && recipe.rootTitle != null)
                        Text(
                          '📌 ${'recipe.basedOnRecipe'.tr(namedArgs: {'title': recipe.rootTitle!})}',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(bool isVariant) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isVariant ? Colors.orange : const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isVariant ? 'recipe.variant'.tr() : 'recipe.originalBadge'.tr(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Activity counts row: shows variant count and log count
  Widget _buildActivityRow(RecipeSummary recipe) {
    final hasVariants = recipe.variantCount > 0;
    final hasLogs = recipe.logCount > 0;

    // If no activity, don't show the row
    if (!hasVariants && !hasLogs) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (hasVariants) ...[
          Text(
            '🔀 ${'recipe.variantCountLabel'.tr(namedArgs: {'count': recipe.variantCount.toString()})}',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (hasVariants && hasLogs) ...[
          Text(
            " · ",
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
        if (hasLogs) ...[
          Text(
            '📝 ${'recipe.logCountLabel'.tr(namedArgs: {'count': recipe.logCount.toString()})}',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange[50],
      child: Row(
        children: [
          Icon(Icons.access_time, size: 14, color: Colors.orange[700]),
          const SizedBox(width: 6),
          Text(
            'recipe.offlineData'.tr(namedArgs: {'time': timeText}),
            style: TextStyle(fontSize: 12, color: Colors.orange[700]),
          ),
        ],
      ),
    );
  }
}
