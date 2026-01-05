import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
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
      appBar: AppBar(
        title: const Text(
          "레시피 탐색",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recipeListProvider);
          return ref.read(recipeListProvider.future);
        },
        child: recipesAsync.when(
          data: (state) {
            final recipes = state.items; // 💡 실제 리스트 데이터 추출
            final hasNext = state.hasNext; // 💡 다음 페이지 존재 여부 추출

            // 데이터가 없을 때도 스크롤 가능하게 ListView를 반환
            if (recipes.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "등록된 레시피가 없습니다.",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "화면을 당겨서 새로고침 해보세요.",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              // 💡 다음 페이지가 있을 때만 로딩 인디케이터를 위한 공간(+1)을 확보합니다.
              itemCount: hasNext ? recipes.length + 1 : recipes.length,
              itemBuilder: (context, index) {
                // 💡 다음 페이지가 있고, 마지막 인덱스일 때 로딩바 표시
                if (hasNext && index == recipes.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final recipe = recipes[index];
                final card = _buildRecipeCard(context, recipe);

                // 💡 더 이상 데이터가 없을 때 하단에 안내 문구 표시 (선택 사항)
                if (!hasNext && index == recipes.length - 1) {
                  return Column(
                    children: [
                      card,
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          "모든 레시피를 불러왔습니다.",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ],
                  );
                }

                return card;
              },
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
                    Text("오류가 발생했습니다: $err"),
                    TextButton(
                      onPressed: () => ref.invalidate(recipeListProvider),
                      child: const Text("다시 시도"),
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

  Widget _buildRecipeCard(BuildContext context, RecipeSummary recipe) {
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
                  Text(
                    recipe.foodName,
                    style: TextStyle(
                      color: Colors.indigo[900],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 12),
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
                      if (recipe.variantCount > 0)
                        Text(
                          "변형 ${recipe.variantCount}개",
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
        isVariant ? "변형" : "오리지널",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
