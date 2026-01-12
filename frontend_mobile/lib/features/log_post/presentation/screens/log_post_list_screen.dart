import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/models/log_outcome.dart';
import 'package:pairing_planet2_frontend/core/providers/scroll_to_top_provider.dart';
import 'package:pairing_planet2_frontend/core/widgets/empty_states/search_empty_state.dart';
import 'package:pairing_planet2_frontend/core/widgets/log_post_card.dart';
import 'package:pairing_planet2_frontend/core/widgets/skeletons/log_post_card_skeleton.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_list_provider.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_filter_provider.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/hero_search_icon.dart';
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  Widget _buildFilterTabs() {
    final filterState = ref.watch(logFilterProvider);
    final selectedOutcomes = filterState.selectedOutcomes;

    // Determine which tab is selected
    final isAllSelected = selectedOutcomes.isEmpty;
    final isWinsSelected = selectedOutcomes.length == 1 &&
        selectedOutcomes.contains(LogOutcome.success);
    final isLearningSelected = selectedOutcomes.containsAll({LogOutcome.partial, LogOutcome.failed}) &&
        selectedOutcomes.length == 2;

    return Padding(
      padding: EdgeInsets.only(left: 16.w),
      child: Row(
        children: [
          _FilterTab(
            label: 'logPost.filter.all'.tr(),
            isSelected: isAllSelected,
            onTap: () {
              if (isAllSelected) return;
              HapticFeedback.selectionClick();
              ref.read(logFilterProvider.notifier).clearOutcomeFilters();
            },
          ),
          SizedBox(width: 24.w),
          _FilterTab(
            label: 'logPost.filter.wins'.tr(),
            isSelected: isWinsSelected,
            onTap: () {
              if (isWinsSelected) return;
              HapticFeedback.selectionClick();
              ref.read(logFilterProvider.notifier).setOutcome(LogOutcome.success);
            },
          ),
          SizedBox(width: 24.w),
          _FilterTab(
            label: 'logPost.filter.learning'.tr(),
            isSelected: isLearningSelected,
            onTap: () {
              if (isLearningSelected) return;
              HapticFeedback.selectionClick();
              ref.read(logFilterProvider.notifier).setLearningFilter();
            },
          ),
        ],
      ),
    );
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
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(logPostPaginatedListProvider.notifier).refresh();
        },
        child: NestedScrollViewPlus(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // SliverAppBar with filter tabs and search button
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              scrolledUnderElevation: innerBoxIsScrolled ? 1 : 0,
              titleSpacing: 0,
              title: _buildFilterTabs(),
              actions: [
                HeroSearchIcon(
                  onTap: () => context.push(RouteConstants.search),
                  heroTag: 'search-hero',
                ),
              ],
            ),
          ],
          body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              final metrics = notification.metrics;
              if (metrics.pixels >= metrics.maxScrollExtent * 0.8) {
                ref.read(logPostPaginatedListProvider.notifier).fetchNextPage();
              }
            }
            return false;
          },
          child: Builder(
            builder: (context) {
              return logPostsAsync.when(
                data: (state) => _buildContentBody(state),
                loading: () => const LogPostGridSkeleton(),
                error: (error, stack) => _buildErrorState(error),
              );
            },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentBody(LogPostListState state) {
    // Empty state
    if (state.items.isEmpty) {
      return Column(
        children: [
          const SyncStatusIndicator(variant: SyncStatusVariant.banner),
          Expanded(child: _buildEmptyStateContent(state.searchQuery)),
        ],
      );
    }

    // Grid of log posts
    return CustomScrollView(
      slivers: [
        // Sync status banner (shows when there are pending items)
        const SliverToBoxAdapter(
          child: SyncStatusIndicator(variant: SyncStatusVariant.banner),
        ),
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
                  final logPost = state.items[index];
                  final outcome = LogOutcome.fromString(logPost.outcome) ?? LogOutcome.partial;
                  return Semantics(
                    button: true,
                    label: '${outcome.label}: ${logPost.title}',
                    hint: 'logPost.card.tapToView'.tr(),
                    child: LogPostCard(
                      log: logPost,
                      searchQuery: state.searchQuery,
                      onTap: () {
                        // Don't navigate to detail if pending (not yet synced)
                        if (logPost.isPending) {
                          HapticFeedback.lightImpact();
                          return;
                        }
                        HapticFeedback.selectionClick();
                        context.push(RouteConstants.logPostDetailPath(logPost.id));
                      },
                    ),
                  );
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

/// Filter tab with underline indicator
class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : Colors.grey[500],
            ),
          ),
          SizedBox(height: 6.h),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3.h,
            width: isSelected ? 24.w : 0,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(1.5.r),
            ),
          ),
        ],
      ),
    );
  }
}
