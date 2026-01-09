import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/login_prompt_sheet.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_providers.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/hashtag_chips.dart';
import '../widgets/log_recipe_lineage.dart';

class LogPostDetailScreen extends ConsumerStatefulWidget {
  final String logId;

  const LogPostDetailScreen({super.key, required this.logId});

  @override
  ConsumerState<LogPostDetailScreen> createState() => _LogPostDetailScreenState();
}

class _LogPostDetailScreenState extends ConsumerState<LogPostDetailScreen> {
  bool _saveStateInitialized = false;

  @override
  Widget build(BuildContext context) {
    final logAsync = ref.watch(logPostDetailProvider(widget.logId));
    final saveState = ref.watch(saveLogProvider(widget.logId));

    // Initialize save state when log data loads
    ref.listen(logPostDetailProvider(widget.logId), (_, next) {
      next.whenData((log) {
        if (!_saveStateInitialized && log.isSavedByCurrentUser != null) {
          ref.read(saveLogProvider(widget.logId).notifier)
              .setInitialState(log.isSavedByCurrentUser!);
          _saveStateInitialized = true;
        }
      });
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('logPost.detail'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Bookmark button
          saveState.when(
            data: (isSaved) => IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? AppColors.primary : Colors.grey[600],
              ),
              onPressed: () {
                final authStatus = ref.read(authStateProvider).status;
                if (authStatus != AuthStatus.authenticated) {
                  LoginPromptSheet.show(
                    context: context,
                    actionKey: 'guest.signInToSave',
                    pendingAction: () {
                      ref.read(saveLogProvider(widget.logId).notifier).toggle();
                    },
                  );
                  return;
                }
                ref.read(saveLogProvider(widget.logId).notifier).toggle();
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
      body: logAsync.when(
        data: (log) => Column(
          children: [
            // Recipe lineage at TOP (shows which recipe was used and its origin)
            LogRecipeLineage(linkedRecipe: log.linkedRecipe),
            Expanded(
              child: SingleChildScrollView(
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
                          // 2. 날짜 및 결과
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
                          Text(
                            'logPost.myReview'.tr(),
                            style: const TextStyle(
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

                          // 4. 해시태그
                          if (log.hashtags.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              'logPost.hashtags'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            HashtagChips(hashtags: log.hashtags),
                          ],

                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('common.errorWithMessage'.tr(namedArgs: {'message': err.toString()}))),
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
}
