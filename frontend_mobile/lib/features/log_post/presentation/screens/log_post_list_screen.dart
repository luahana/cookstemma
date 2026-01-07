import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/empty_states/search_empty_state.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/enhanced_search_app_bar.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/highlighted_text.dart';
import 'package:pairing_planet2_frontend/core/widgets/skeletons/log_post_card_skeleton.dart';
import 'package:pairing_planet2_frontend/data/datasources/search/search_local_data_source.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
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

  String _getOutcomeEmoji(String? outcome) {
    return switch (outcome) {
      'SUCCESS' => '😊',
      'PARTIAL' => '😐',
      'FAILED' => '😢',
      _ => '🍳',
    };
  }

  @override
  Widget build(BuildContext context) {
    final logPostsAsync = ref.watch(logPostPaginatedListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: EnhancedSearchAppBar(
        title: '요리 기록',
        hintText: '요리 기록 검색...',
        currentQuery: logPostsAsync.valueOrNull?.searchQuery,
        searchType: SearchType.logPost,
        onSearch: (query) {
          ref.read(logPostPaginatedListProvider.notifier).search(query);
        },
        onClear: () {
          ref.read(logPostPaginatedListProvider.notifier).clearSearch();
        },
      ),
      body: logPostsAsync.when(
        data: (state) {
          if (state.items.isEmpty) {
            return _buildEmptyState(state.searchQuery);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(logPostPaginatedListProvider.notifier).refresh();
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Grid of log posts
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < state.items.length) {
                          return _buildLogCard(context, state.items[index], state.searchQuery);
                        }
                        return null;
                      },
                      childCount: state.items.length,
                    ),
                  ),
                ),
                // Loading indicator at the bottom
                if (state.hasNext)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                // End message when no more items
                if (!state.hasNext && state.items.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          "모든 요리 기록을 불러왔습니다",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const LogPostGridSkeleton(),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, LogPostSummary logPost, String? searchQuery) {
    return GestureDetector(
      onTap: () => context.push(RouteConstants.logPostDetailPath(logPost.id)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo with outcome overlay
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Photo
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: logPost.thumbnailUrl != null
                        ? AppCachedImage(
                            imageUrl: logPost.thumbnailUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: 0,
                          )
                        : Container(
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.restaurant,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                  // Outcome emoji overlay
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        _getOutcomeEmoji(logPost.outcome),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Text info
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HighlightedText(
                      text: logPost.title,
                      query: searchQuery,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (logPost.creatorName != null)
                      Text(
                        "@${logPost.creatorName}",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String? searchQuery) {
    // 검색 결과가 없는 경우
    if (searchQuery != null && searchQuery.isNotEmpty) {
      return SearchEmptyState(
        query: searchQuery,
        entityName: '요리 기록',
        onClearSearch: () {
          ref.read(logPostPaginatedListProvider.notifier).clearSearch();
        },
      );
    }

    // 일반 빈 상태
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.history_edu,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                "아직 요리 기록이 없어요",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "레시피를 따라 요리하고\n기록을 남겨보세요!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            '로그를 불러올 수 없습니다',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center,
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
    );
  }
}
