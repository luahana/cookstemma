import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/providers/scroll_to_top_provider.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/empty_states/search_empty_state.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/enhanced_search_app_bar.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/highlighted_text.dart';
import 'package:pairing_planet2_frontend/core/widgets/skeletons/log_post_card_skeleton.dart';
import 'package:pairing_planet2_frontend/data/datasources/search/search_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/sync/sync_queue_item.dart';
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

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  LogOutcome _getOutcome(String? outcome) {
    return LogOutcome.fromString(outcome) ?? LogOutcome.partial;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to scroll-to-top events for tab index 2 (Logs)
    ref.listen<int>(scrollToTopProvider(2), (previous, current) {
      if (previous != null && current != previous) {
        _scrollToTop();
      }
    });

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
                // Filter bar at the top (pinned/sticky)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FilterBarDelegate(
                    height: 48.h,
                    child: CompactLogFilterBar(
                      onFilterChanged: () {
                        // Provider auto-refreshes on filter change
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                ),
                // Empty state or grid of log posts
                if (state.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyStateContent(state.searchQuery),
                  )
                else ...[
                  // Grid of log posts
                  SliverPadding(
                    padding: EdgeInsets.all(12.r),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12.h,
                        crossAxisSpacing: 12.w,
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
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24.r),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  // End message when no more items
                  if (!state.hasNext)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24.r),
                        child: Center(
                          child: Text(
                            'logPost.allLoaded'.tr(),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
          // Don't navigate to detail if pending (not yet synced)
          if (logPost.isPending) {
            HapticFeedback.lightImpact();
            return;
          }
          HapticFeedback.selectionClick();
          context.push(RouteConstants.logPostDetailPath(logPost.id));
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
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
                    // Photo - handle both network URLs and local file paths
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                      child: _buildThumbnail(logPost),
                    ),
                    // Outcome badge overlay (top-left for prominence)
                    Positioned(
                      left: 8.w,
                      top: 8.h,
                      child: OutcomeBadge(
                        outcome: outcome,
                        variant: OutcomeBadgeVariant.compact,
                      ),
                    ),
                    // Sync status indicator for pending items (top-right)
                    if (logPost.isPending)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: CardSyncIndicator(
                          status: SyncStatus.syncing,
                        ),
                      ),
                  ],
                ),
              ),
              // Text info
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.all(10.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HighlightedText(
                        text: logPost.title,
                        query: searchQuery,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      if (logPost.isPending)
                        Text(
                          'logPost.sync.syncing'.tr(),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.orange[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (logPost.creatorName != null)
                        Text(
                          "@${logPost.creatorName}",
                          style: TextStyle(
                            fontSize: 11.sp,
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

  /// Build thumbnail widget - handles both network URLs and local file paths
  Widget _buildThumbnail(LogPostSummary logPost) {
    if (logPost.thumbnailUrl == null) {
      return Container(
        width: double.infinity,
        color: Colors.grey[200],
        child: Icon(
          Icons.restaurant,
          size: 40.sp,
          color: Colors.grey[400],
        ),
      );
    }

    // Handle local file URLs (for pending items)
    if (logPost.thumbnailUrl!.startsWith('file://')) {
      final filePath = logPost.thumbnailUrl!.replaceFirst('file://', '');
      return Image.file(
        File(filePath),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            color: Colors.grey[200],
            child: Icon(
              Icons.broken_image,
              size: 40.sp,
              color: Colors.grey[400],
            ),
          );
        },
      );
    }

    // Network URL
    return AppCachedImage(
      imageUrl: logPost.thumbnailUrl!,
      width: double.infinity,
      height: double.infinity,
      borderRadius: 0,
    );
  }

  Widget _buildEmptyStateContent(String? searchQuery) {
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
    return const LogEmptyState(
      type: EmptyStateType.noLogs,
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
          SizedBox(height: 16.h),
          Text(
            'logPost.couldNotLoad'.tr(),
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 8.h),
          Text(
            error.toString(),
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
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

/// Delegate for sticky filter bar header
class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _FilterBarDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: Material(
        color: Colors.white,
        elevation: overlapsContent ? 2 : 0,
        child: child,
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _FilterBarDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}
