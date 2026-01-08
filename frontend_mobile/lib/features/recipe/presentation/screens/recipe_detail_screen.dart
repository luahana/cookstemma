import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/ingredient_dto.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import '../../providers/recipe_providers.dart';
import '../widgets/lineage_breadcrumb.dart';
import '../widgets/recent_logs_gallery.dart';
import '../widgets/variants_gallery.dart';
import '../widgets/hashtag_chips.dart';
import '../widgets/share_bottom_sheet.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  bool _saveStateInitialized = false;

  @override
  Widget build(BuildContext context) {
    // Use the tracking provider to log recipe views
    final recipeAsync = ref.watch(recipeDetailWithTrackingProvider(widget.recipeId));
    final saveState = ref.watch(saveRecipeProvider(widget.recipeId));

    // P1: 레시피 데이터 로드 시 저장 상태 초기화
    ref.listen(recipeDetailWithTrackingProvider(widget.recipeId), (_, next) {
      next.whenData((recipe) {
        if (!_saveStateInitialized && recipe.isSavedByCurrentUser != null) {
          ref.read(saveRecipeProvider(widget.recipeId).notifier)
              .setInitialState(recipe.isSavedByCurrentUser!);
          _saveStateInitialized = true;
        }
      });
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("레시피 상세"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Share button
          recipeAsync.maybeWhen(
            data: (recipe) => IconButton(
              icon: Icon(Icons.share, color: Colors.grey[600]),
              onPressed: () {
                ShareBottomSheet.show(
                  context,
                  recipePublicId: widget.recipeId,
                  recipeTitle: recipe.title,
                );
              },
            ),
            orElse: () => IconButton(
              icon: Icon(Icons.share, color: Colors.grey[400]),
              onPressed: null,
            ),
          ),
          // P1: 북마크 버튼
          saveState.when(
            data: (isSaved) => IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? const Color(0xFF1A237E) : Colors.grey[600],
              ),
              onPressed: () {
                ref.read(saveRecipeProvider(widget.recipeId).notifier).toggle();
              },
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => IconButton(
              icon: Icon(Icons.bookmark_border, color: Colors.grey[400]),
              onPressed: null,
            ),
          ),
        ],
      ),
      body: recipeAsync.when(
        data: (recipe) => Column(
          children: [
            // Lineage breadcrumb at TOP (for variant recipes)
            LineageBreadcrumb(
              rootInfo: recipe.rootInfo,
              parentInfo: recipe.parentInfo,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageHeader(recipe),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLineageTag(recipe),
                          const SizedBox(height: 12),
                          Text(
                            "[${recipe.foodName}]",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.indigo[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            recipe.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            recipe.description ?? "",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                          // Hashtags section
                          if (recipe.hashtags.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            HashtagChips(hashtags: recipe.hashtags),
                          ],
                          const Divider(height: 48),
                          const Text(
                            "준비 재료",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildIngredientSection(
                            "주재료",
                            recipe.ingredients,
                            IngredientType.MAIN,
                          ),
                          _buildIngredientSection(
                            "부재료",
                            recipe.ingredients,
                            IngredientType.SECONDARY,
                          ),
                          _buildIngredientSection(
                            "양념",
                            recipe.ingredients,
                            IngredientType.SEASONING,
                          ),
                          const Divider(height: 48),
                          const Text(
                            "조리 순서",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...recipe.steps.map((step) => _buildStepItem(step)),
                        ],
                      ),
                    ),
                    // Variants Gallery section (only for ROOT recipes with variants)
                    if (recipe.variants.isNotEmpty && recipe.rootInfo == null) ...[
                      const Divider(height: 48),
                      VariantsGallery(
                        variants: recipe.variants,
                        recipeId: recipe.publicId,
                      ),
                    ],
                    // Recent Logs Gallery section
                    const Divider(height: 48),
                    RecentLogsGallery(
                      logs: recipe.logs,
                      recipeId: recipe.publicId,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            // 💡 하단 고정 버튼 섹션 추가
            _buildBottomActionButtons(context, recipe),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("데이터를 가져오지 못했습니다: $err"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(recipeDetailProvider(widget.recipeId)),
                child: const Text("다시 시도"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 💡 하단 변형하기 & 로그 기록하기 버튼 레이아웃
  Widget _buildBottomActionButtons(BuildContext context, RecipeDetail recipe) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. 로그 기록하기 버튼 (좌측)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // 💡 로그 작성을 위한 경로로 이동 (RouteConstants에 정의 필요)
                context.push(RouteConstants.logPostCreate, extra: recipe);
              },
              icon: const Icon(Icons.history_edu),
              label: const Text("로그 기록"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: Color(0xFF1A237E)),
                foregroundColor: const Color(0xFF1A237E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 2. 변형하기 버튼 (우측)
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              onPressed: () =>
                  context.push(RouteConstants.recipeCreate, extra: recipe),
              icon: const Icon(Icons.alt_route, color: Colors.white),
              label: const Text("변형하기", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E), // 남색 스타일 적용
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineageTag(RecipeDetail recipe) {
    final isVariant = recipe.parentInfo != null || recipe.rootInfo != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isVariant ? Colors.orange[50] : Colors.indigo[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isVariant ? "변형 레시피" : "오리지널 레시피",
        style: TextStyle(
          color: isVariant ? Colors.orange[800] : Colors.indigo[800],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildIngredientSection(
    String title,
    List<dynamic> allIngredients,
    IngredientType type,
  ) {
    final items = allIngredients.where((i) => i.type == type.name).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo[900],
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(i.name, style: const TextStyle(fontSize: 15)),
                  Text(
                    i.amount ?? "",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(dynamic step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.indigo[900],
                child: Text(
                  "${step.stepNumber}",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              const Text("단계", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (step.imageUrl != null && step.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCachedImage(
                imageUrl: step.imageUrl!,
                width: double.infinity,
                height: 200,
                borderRadius: 12,
              ),
            ),
          Text(
            step.description,
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildImageHeader(RecipeDetail recipe) {
    return AppCachedImage(
      imageUrl: recipe.imageUrls.isNotEmpty
          ? recipe.imageUrls.first
          : 'https://via.placeholder.com/400x250',
      width: double.infinity,
      height: 300,
      borderRadius: 0,
    );
  }
}
