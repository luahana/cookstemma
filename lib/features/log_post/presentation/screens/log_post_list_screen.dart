import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_list_provider.dart';

class LogPostListScreen extends ConsumerStatefulWidget {
  const LogPostListScreen({super.key});

  @override
  ConsumerState<LogPostListScreen> createState() => _LogPostListScreenState();
}

class _LogPostListScreenState extends ConsumerState<LogPostListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(logPostPaginatedListProvider.notifier).fetchNextPage();
    }
  }

  Widget _buildOutcomeEmoji(String? outcome) {
    final emoji = switch (outcome) {
      'SUCCESS' => '😊',
      'PARTIAL' => '😐',
      'FAILED' => '😢',
      _ => '😐',
    };
    return Text(emoji, style: const TextStyle(fontSize: 20));
  }

  @override
  Widget build(BuildContext context) {
    final logPostsAsync = ref.watch(logPostPaginatedListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('로그'),
        centerTitle: true,
      ),
      body: logPostsAsync.when(
        data: (state) {
          if (state.items.isEmpty) {
            return const Center(
              child: Text(
                '아직 작성된 로그가 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(logPostPaginatedListProvider.notifier).refresh();
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length + (state.hasNext ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.items.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final logPost = state.items[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      context.push(
                        RouteConstants.logPostDetailPath(logPost.id),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (logPost.thumbnailUrl != null)
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: CachedNetworkImage(
                              imageUrl: logPost.thumbnailUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                logPost.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              if (logPost.outcome != null)
                                _buildOutcomeEmoji(logPost.outcome),
                              const SizedBox(height: 8),
                              if (logPost.creatorName != null)
                                Text(
                                  'by ${logPost.creatorName}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '로그를 불러올 수 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(logPostPaginatedListProvider);
                },
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
