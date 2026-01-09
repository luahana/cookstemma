import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:pairing_planet2_frontend/features/log_post/providers/log_filter_provider.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/outcome_badge.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/log_filter_bar.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/log_empty_state.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/sync_status_indicator.dart';

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

  LogOutcome _getOutcome(String? outcome) {
    return LogOutcome.fromString(outcome) ?? LogOutcome.partial;
  }

  @override
  Widget build(BuildContext context) {
    final logPostsAsync = ref.watch(logPostPaginatedListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: EnhancedSearchAppBar(
        title: 'logPost.title'.tr(),
        hintText: 'logPost.searchHint'.tr(),
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
                // Sync status banner (shows when there are pending items)
                const SliverToBoxAdapter(
                  child: SyncStatusIndicator(variant: SyncStatusVariant.banner),
                ),
                // Filter bar at the top
                SliverToBoxAdapter(
                  child: CompactLogFilterBar(
                    onFilterChanged: () {
                      // Provider auto-refreshes on filter change
                      HapticFeedback.selectionClick();
                    },
                  ),
                ),
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
                          'logPost.allLoaded'.tr(),
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
    final outcome = _getOutcome(logPost.outcome);

    return Semantics(
      button: true,
      label: '${outcome.label}: ${logPost.title}',
      hint: 'logPost.card.tapToView'.tr(),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push(RouteConstants.logPostDetailPath(logPost.id));
        },
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
              // Photo with outcome badge overlay
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
                    // Outcome badge overlay (top-left for prominence)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: OutcomeBadge(
                        outcome: outcome,
                        variant: OutcomeBadgeVariant.compact,
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
      ),
    );
  }

  Widget _buildEmptyState(String? searchQuery) {
    // Check if filters are active
    final filterState = ref.watch(logFilterProvider);

    // Search results empty
    if (searchQuery != null && searchQuery.isNotEmpty) {
      return SearchEmptyState(
        query: searchQuery,
        entityName: 'logPost.title'.tr(),
        onClearSearch: () {
          ref.read(logPostPaginatedListProvider.notifier).clearSearch();
        },
      );
    }

    // Filter results empty
    if (filterState.hasActiveFilters) {
      return FilterEmptyState(
        onClearFilters: () {
          HapticFeedback.lightImpact();
          ref.read(logFilterProvider.notifier).clearAllFilters();
        },
      );
    }

    // No logs at all - show illustrated empty state
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(logPostPaginatedListProvider.notifier).refresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: const LogEmptyState(
            type: EmptyStateType.noLogs,
          ),
        ),
      ),
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
            'logPost.couldNotLoad'.tr(),
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
            child: Text('common.tryAgain'.tr()),
          ),
        ],
      ),
    );
  }
}
