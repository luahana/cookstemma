import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_providers.dart';

class LogPostDetailScreen extends ConsumerWidget {
  final String logId;

  const LogPostDetailScreen({super.key, required this.logId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(logPostDetailProvider(logId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("요리 로그 상세"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: logAsync.when(
        data: (log) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 이미지 갤러리 (가로 스크롤)
              _buildImageGallery(log.imageUrls),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. 날짜 및 평점
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('yyyy년 MM월 dd일').format(log.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        _buildOutcomeEmoji(log.outcome),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 3. 로그 본문 내용
                    const Text(
                      "나의 요리 후기",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      log.content,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),

                    const Divider(height: 48),

                    // 4. 연결된 레시피 정보 카드
                    const Text(
                      "참고한 레시피",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLinkedRecipeCard(context, log.recipePublicId),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("에러 발생: $err")),
      ),
    );
  }

  // 💡 여러 장의 사진을 보여주는 갤러리 위젯
  Widget _buildImageGallery(List<String?> urls) {
    if (urls.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AppCachedImage(
              imageUrl: urls[index],
              width: MediaQuery.of(context).size.width * 0.8,
              height: 300,
              borderRadius: 16,
            ),
          );
        },
      ),
    );
  }

  // 💡 요리 결과 이모지 표시
  Widget _buildOutcomeEmoji(String outcome) {
    final emoji = switch (outcome) {
      'SUCCESS' => '😊',
      'PARTIAL' => '😐',
      'FAILED' => '😢',
      _ => '😐',
    };
    return Text(emoji, style: const TextStyle(fontSize: 24));
  }

  // 💡 클릭 시 해당 레시피로 이동하는 카드
  Widget _buildLinkedRecipeCard(BuildContext context, String recipeId) {
    return GestureDetector(
      onTap: () => context.push(RouteConstants.recipeDetailPath(recipeId)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.indigo[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.indigo[100]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.restaurant_menu, color: Color(0xFF1A237E)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "레시피 상세 정보 보러가기",
                style: TextStyle(
                  color: Color(0xFF1A237E),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF1A237E)),
          ],
        ),
      ),
    );
  }
}
