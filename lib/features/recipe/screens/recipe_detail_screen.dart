import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import '../providers/recipe_providers.dart';

class RecipeDetailScreen extends ConsumerWidget {
  final String recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 recipeDetailProvider를 구독하고 상태를 감시함
    final recipeAsync = ref.watch(recipeDetailProvider(recipeId));

    return Scaffold(
      appBar: AppBar(title: const Text("레시피 상세")),
      body: recipeAsync.when(
        // 데이터 로드 성공 시
        data: (recipe) => SingleChildScrollView(
          child: Column(
            children: [
              if (recipe.imageUrls.isNotEmpty)
                Image.network(recipe.imageUrls.first),
              Text(
                recipe.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(recipe.description),
              // ... 재료 및 조리 단계 렌더링
            ],
          ),
        ),
        // 로딩 중일 때
        loading: () => const Center(child: CircularProgressIndicator()),
        // 에러 발생 시
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("데이터를 가져오지 못했습니다: $err"),
              ElevatedButton(
                onPressed: () => ref.refresh(recipeDetailProvider(recipeId)),
                child: const Text("다시 시도"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageHeader(RecipeDetail recipe) {
    return AppCachedImage(
      imageUrl: recipe.imageUrls.isNotEmpty
          ? recipe.imageUrls.first
          : 'https://placeholder.com/default.png',
      width: double.infinity,
      height: 250,
      borderRadius: 12, // 둥근 모서리 적용
    );
  }
}
